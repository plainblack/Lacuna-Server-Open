use 5.010;
use strict;
use warnings;
use lib '/data/Lacuna-Server/lib';

use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);

use Getopt::Long;
use List::MoreUtils qw(uniq);
use Data::Dumper;

$|=1;
our $quiet      = 0; # omit output messages
our $respawn    = 0; # delete and respawn the empire
our $add        = 0; # the number of colonies to add
our $each_level = 0; # Add one colony of each level

GetOptions(
    'quiet'      => \$quiet,  
    'respawn'    => \$respawn,
    'add=i'      => \$add,
    'each_level' => \$each_level,
);

out('Started');
my $start = time;

out('Loading DB');
our $db     = Lacuna->db;
my $config  = Lacuna->config;
my $empires = $db->resultset('Lacuna::DB::Result::Empire');
my $empire;

if ($respawn) {
    # with 'respawn' we delete and re-create the whole empire
    out('Re-Spawning Empire');
    $db->resultset('Lacuna::DB::Result::AIScratchPad')->search->delete;

    $empire = $empires->find(-9);

    if (defined $empire) {
        out('Deleting existing empire');
        # First ensure we have demolished all glyph resource buildings
        for my $planet ($empire->planets->all) {
            out("Removing sensitive buildings from ".$planet->name);
            $planet->delete_buildings(@{$planet->building_cache});

            # Rename the planet 
            $planet->name($planet->star->name." ".$planet->orbit);
            $planet->update;
        }

        $empire->delete;
    }
}

$empire = $empires->find(-9);
if (not defined $empire) {
    out('Creating new empire');
    $empire = create_empire();
}

# We need to determine how many DeLambert colonies to add to each zone
# we ignore the neutral zone
# we ignore zone 0|0 since it is already highly occupied already
# we want to put DeLambert colonies in zones such that the ratio of other empires
# colonies to DeLambert colonies is fairly constant.
#
# First work out how many bodies are occupied in each zone which are *not* DeLambert
my @zone_empire = $db->resultset('Lacuna::DB::Result::Map::Body')->search({
    -and => [
        empire_id   => {'>'  => 1},             # Ignore all AI empires
        empire_id   => {'!=' => $empire->id},
#        zone        => {'!=' => '0|0'},         # Central zone is too populated
        zone        => {'!=' => '-3|0'},         # Ignore the neutral zone
    ],
},{
    group_by => [qw(zone)],
    select => [
        'zone',
        { count => 'id', -as => 'count_bodies'},
    ],
    as => ['zone','occupied'],
    order_by => {-desc => 'count_bodies'},
});

out("There are ".scalar(@zone_empire)." zones occupied by empires");
out("    Zone\tCount");
my $empire_occupied = 0;
for my $zone (@zone_empire) {
    out("    ".$zone->zone."\t".$zone->get_column('occupied'));
    $empire_occupied += $zone->get_column('occupied');
}
out("    Total\t$empire_occupied");

# Now, how many deLambert bodies are in each zone
my @zone_delambert = $db->resultset('Lacuna::DB::Result::Map::Body')->search({
    empire_id => $empire->id,
},{
    group_by => [qw(zone)],
    select => [
        'zone',
        { count => 'id', -as => 'count_bodies'},
    ],
    as => ['zone','occupied'],
    order_by => {-desc => 'count_bodies'},
});

out("There are ".scalar(@zone_delambert)." zones occupied by DeLamberti");
out("    Zone\tCount");
my $total_delamberti = 0;
my $delamberti_in;
for my $zone (@zone_delambert) {
    my $delamberti_in_zone = $zone->get_column('occupied');
    out("    ".$zone->zone."\t$delamberti_in_zone");
    $total_delamberti += $delamberti_in_zone;
    $delamberti_in->{$zone->zone} = $delamberti_in_zone;
}
out("    Total\t$total_delamberti");

# Now we know how many empires are in each zone, and how many DeLamberti
# we can determine which zones have the lowest proportion of DeLamberti
# (or noDeLamberti) and add new ones there.
#
# Calculate the levels we want
#

my @build_levels;

if ($each_level) {
    push @build_levels,(5,10,15,20,25);
}
else {
    my @levels = (5,10,15,20,20,25,25,30);
    foreach (1..$add) {
        my $level = $levels[randint(0,scalar(@levels)-1)];
        push @build_levels, $level;
    }
}

#
for my $level(@build_levels) {
    out("Adding a new colony");
    # Find the zone with the lowest ratio of colonies to DeLamberti colonies
    my $add_to_zone = '';
    my $lowest_ratio = 999999999;
    my $delamberti_in_lowest_zone = 0;
    for my $zone (@zone_empire) {
        my $delamberti_in_zone  = $delamberti_in->{$zone->zone} || 0;
        my $colonies_in_zone    = $zone->get_column('occupied') || 1;
        my $ratio = $delamberti_in_zone / $colonies_in_zone;
        if ($ratio < $lowest_ratio) {
            $lowest_ratio = $ratio;
            $add_to_zone = $zone->zone;
            $delamberti_in_lowest_zone = $delamberti_in_zone;
        }
    }
    out("Add colony to zone $add_to_zone");
    # Choose a colony size at random (weighted)
    #
    my $sizes  = {5 => [50,60], 10 => [70,80], 15 => [80,90], 20 => [90,100], 25 => [100, 110], 30 => [110,121]};
    out("Creating a colony level $level");

    # We want to find a colony in an un-occupied star system
    my $body;
    my $stars_rs = $db->resultset('Lacuna::DB::Result::Map::Star')->search({zone => $add_to_zone});
    STAR:
    while (my $star = $stars_rs->next) {
        # Ensure there are no occupied bodies in this system
        my $occupied_bodies = $star->bodies->search({empire_id => {'!=' => undef }});
        next STAR if $occupied_bodies > 0;

        $body = $star->bodies->search({
            class   => {-like => ['%Planet::GasGiant::G%','%:Planet::P%']},
            -and    => [size => {'>=' => $sizes->{$level}[0]}, size => {'<' => $sizes->{$level}[1] }],
            orbit   => {'<' => 8},
        })->first;
        next STAR if not $body;
        out("Putting colony in star system ".$star->name);
        last STAR;
        
    }
    die "Cannot find a star in zone $add_to_zone" unless $body;

    $body->delete_buildings(@{$body->building_cache});
    $body->found_colony($empire);
    create_colony($level, $body);
    $delamberti_in->{$add_to_zone} = $delamberti_in_lowest_zone + 1;
}


my $finish = time;
out('Finished');
out((int(($finish - $start)/60*100)/100)." minutes have elapsed");

###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}

sub create_empire {
    out('Creating empire...');
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->new({
        id                      => -9,
        name                    => 'DeLambert',
        stage                   => 'founded',
        date_created            => DateTime->now,
        status_message          => 'We come in peace!',
        description             => 'A peaceful trading empire',
        password                => Lacuna::DB::Result::Empire->encrypt_password(rand(99999999)),
        species_name            => 'DeLamberti',
        species_description     => 'A strong species who prefer high G. worlds.',
        min_orbit               => 1,
        max_orbit               => 7,
        manufacturing_affinity  => 2, # cost of building new stuff
        deception_affinity      => 7, # spying ability
        research_affinity       => 2, # cost of upgrading
        management_affinity     => 7, # speed to build
        farming_affinity        => 1, # food
        mining_affinity         => 1, # minerals
        science_affinity        => 7, # energy, propultion, and other tech
        environmental_affinity  => 2, # waste and water
        political_affinity      => 1, # happiness
        trade_affinity          => 7, # speed of cargoships, and amount of cargo hauled
        growth_affinity         => 1, # price and speed of colony ships, and planetary command center start level
    });

    out('Find home planet...');
    my $bodies  = $db->resultset('Lacuna::DB::Result::Map::Body');
    my $zone    = $bodies->get_column('zone')->min;
    my $home    = $bodies->search({
        size    => { '>=' => 110}, 
        zone    => $zone,
        empire_id  => undef,
    })->first;

    $empire->insert;
    $home->delete_buildings(@{$home->building_cache});
    $empire->found($home);
    $empire->university_level(30);
    $empire->update;
    create_colony(30, $home);

    # Create an empire wide scratchpad for the AI
    #
    my $scratch = $db->resultset('Lacuna::DB::Result::AIScratchPad')->create({
        ai_empire_id    => -9,
        body_id         => 0,
        pad             => {status => 'peace'},
    });

    return $empire;
}


sub create_colony {
    my ($level, $body) = @_;

    out("Creating a level $level DeLambert colony on body ".$body->name);
    if ($each_level) {
        $body->name("TLE DeLambert $level");
        $body->update;
    }
    # Create a scratch-pad for the colony
    my $scratch = $db->resultset('Lacuna::DB::Result::AIScratchPad')->create({
        ai_empire_id    => -9,
        body_id         => $body->id,
        pad             => {level => $level},
    });

    out('Upgrading PCC');
    my $pcc = $body->command;
    $pcc->level($level);
    $pcc->update;

    my $has_buildings = {
        '5'   => {
            'Permanent::TheDillonForge'         => {qty => 1, level => 5},
            'Permanent::PyramidJunkSculpture'   => {qty => 1, level => 5},
            'Permanent::NaturalSpring'          => {qty => 1, level => 14},
            'Permanent::GeoThermalVent'         => {qty => 1, level => 15},
            'Permanent::AlgaePond'              => {qty => 1, level => 14},
            'Permanent::Volcano'                => {qty => 1, level => 14},
            'Permanent::InterDimensionalRift'   => {qty => 1, level => 15},
            'Permanent::CrashedShipSite'        => {qty => 1, level => 20},

            'Waste::Sequestration'              => {qty => 2, level => 15},
            'Intelligence'                      => {qty => 1, level => 15},
            'Security'                          => {qty => 1, level => 15},
            'Espionage'                         => {qty => 1, level => 15},
            'CloakingLab'                       => {qty => 1, level => 10},
            'Propulsion'                        => {qty => 1, level => 15},
            'MunitionsLab'                      => {qty => 1, level => 20},
            'Shipyard'                          => {qty => 4, level => 22},
            'SpacePort'                         => {qty => 15,level => 15},
            'Observatory'                       => {qty => 1, level => 15},
            'Food::Burger'                      => {qty => 1, level => 15},
            'Food::Malcud'                      => {qty => 1, level => 15},
            'Food::Syrup'                       => {qty => 1, level => 10},
            'Waste::Digester'                   => {qty => 2, level => 15},
            'Energy::Singularity'               => {qty => 2, level => 15},
            'Water::AtmosphericEvaporator'      => {qty => 2, level => 12},
            'Archaeology'                       => {qty => 1, level => 20},
            'SAW'                               => {qty => 4, level => 10},
            'Waste::Exchanger'                  => {qty => 2, level => 15},
            'Trade'                             => {qty => 1, level => 25},
            'Transporter'                       => {qty => 1, level => 25},
            'Development'                       => {qty => 1, level => 15},
       
        },
        '10'   => {
            'Permanent::TheDillonForge'         => {qty => 1, level => 10},
            'Permanent::GasGiantPlatform'       => {qty => 4, level => 17},
            'Permanent::PyramidJunkSculpture'   => {qty => 1, level => 10},
            'Permanent::NaturalSpring'          => {qty => 1, level => 16},
            'Permanent::GeoThermalVent'         => {qty => 1, level => 19},
            'Permanent::AlgaePond'              => {qty => 1, level => 16},
            'Permanent::Volcano'                => {qty => 1, level => 15},
            'Permanent::InterDimensionalRift'   => {qty => 1, level => 15},
            'Permanent::CrashedShipSite'        => {qty => 1, level => 28},

            'Waste::Sequestration'              => {qty => 2, level => 15},
            'Intelligence'                      => {qty => 1, level => 20},
            'Security'                          => {qty => 1, level => 20},
            'Espionage'                         => {qty => 1, level => 20},
            'CloakingLab'                       => {qty => 1, level => 10},
            'Propulsion'                        => {qty => 1, level => 15},
            'MunitionsLab'                      => {qty => 1, level => 20},
            'Shipyard'                          => {qty => 4, level => 24},
            'SpacePort'                         => {qty => 25,level => 20},
            'Observatory'                       => {qty => 1, level => 15},
            'Food::Burger'                      => {qty => 1, level => 15},
            'Food::Malcud'                      => {qty => 1, level => 15},
            'Food::Syrup'                       => {qty => 1, level => 10},
            'Waste::Digester'                   => {qty => 2, level => 15},
            'Energy::Singularity'               => {qty => 2, level => 15},
            'Archaeology'                       => {qty => 1, level => 20},
            'SAW'                               => {qty => 4, level => 10},
            'Waste::Exchanger'                  => {qty => 2, level => 15},
            'Trade'                             => {qty => 1, level => 25},
            'Transporter'                       => {qty => 1, level => 25},
            'Development'                       => {qty => 1, level => 15},

        },
        '15'   => {
            'Permanent::TheDillonForge'         => {qty => 1, level => 15},
            'Permanent::GasGiantPlatform'       => {qty => 4, level => 20},

            'Permanent::PyramidJunkSculpture'   => {qty => 1, level => 14},
            'Permanent::NaturalSpring'          => {qty => 1, level => 21},
            'Permanent::GeoThermalVent'         => {qty => 1, level => 23},
            'Permanent::AlgaePond'              => {qty => 1, level => 20},
            'Permanent::Volcano'                => {qty => 1, level => 20},
            'Permanent::InterDimensionalRift'   => {qty => 1, level => 20},
            'Permanent::CrashedShipSite'        => {qty => 1, level => 28},

            'Waste::Sequestration'              => {qty => 2, level => 20},
            'Intelligence'                      => {qty => 1, level => 20},
            'Security'                          => {qty => 1, level => 20},
            'Espionage'                         => {qty => 1, level => 20},
            'CloakingLab'                       => {qty => 1, level => 10},
            'Propulsion'                        => {qty => 1, level => 18},
            'MunitionsLab'                      => {qty => 1, level => 20},
            'Shipyard'                          => {qty => 4, level => 26},
            'SpacePort'                         => {qty => 40,level => 23},
            'Observatory'                       => {qty => 1, level => 15},
            'Food::Burger'                      => {qty => 1, level => 15},
            'Food::Malcud'                      => {qty => 1, level => 15},
            'Food::Syrup'                       => {qty => 1, level => 10},
            'Waste::Digester'                   => {qty => 2, level => 15},
            'Energy::Singularity'               => {qty => 2, level => 15},
            'Archaeology'                       => {qty => 1, level => 20},
            'SAW'                               => {qty => 4, level => 10},
            'Waste::Exchanger'                  => {qty => 2, level => 15},
            'Trade'                             => {qty => 1, level => 25},
            'Transporter'                       => {qty => 1, level => 25},
            'Development'                       => {qty => 1, level => 15},

        },
        '20'   => {
            'Permanent::TheDillonForge'         => {qty => 1, level => 20},
            'Permanent::GasGiantPlatform'       => {qty => 4, level => 23},

            'Permanent::PyramidJunkSculpture'   => {qty => 1, level => 17},
            'Permanent::NaturalSpring'          => {qty => 1, level => 22},
            'Permanent::GeoThermalVent'         => {qty => 1, level => 25},
            'Permanent::AlgaePond'              => {qty => 1, level => 22},
            'Permanent::Volcano'                => {qty => 1, level => 21},
            'Permanent::InterDimensionalRift'   => {qty => 1, level => 23},
            'Permanent::CrashedShipSite'        => {qty => 1, level => 28},

            'Waste::Sequestration'              => {qty => 2, level => 20},
            'Intelligence'                      => {qty => 1, level => 22},
            'Security'                          => {qty => 1, level => 22},
            'Espionage'                         => {qty => 1, level => 22},
            'CloakingLab'                       => {qty => 1, level => 22},
            'Propulsion'                        => {qty => 1, level => 22},
            'MunitionsLab'                      => {qty => 1, level => 20},
            'Shipyard'                          => {qty => 4, level => 28},
            'SpacePort'                         => {qty => 50,level => 25},
            'Observatory'                       => {qty => 1, level => 15},
            'Food::Burger'                      => {qty => 1, level => 15},
            'Food::Malcud'                      => {qty => 1, level => 15},
            'Food::Syrup'                       => {qty => 1, level => 10},
            'Waste::Digester'                   => {qty => 2, level => 15},
            'Energy::Singularity'               => {qty => 2, level => 15},
            'Archaeology'                       => {qty => 1, level => 20},
            'SAW'                               => {qty => 4, level => 10},
            'Waste::Exchanger'                  => {qty => 2, level => 15},
            'Trade'                             => {qty => 1, level => 25},
            'Transporter'                       => {qty => 1, level => 25},
            'Development'                       => {qty => 1, level => 15},

        },
        '25'   => {
            'Permanent::TheDillonForge'         => {qty => 1, level => 25},
            'Permanent::GasGiantPlatform'       => {qty => 4, level => 26},

            'Permanent::PyramidJunkSculpture'   => {qty => 1, level => 19},
            'Permanent::NaturalSpring'          => {qty => 1, level => 25},
            'Permanent::GeoThermalVent'         => {qty => 1, level => 27},
            'Permanent::AlgaePond'              => {qty => 1, level => 25},
            'Permanent::Volcano'                => {qty => 1, level => 24},
            'Permanent::InterDimensionalRift'   => {qty => 1, level => 26},
            'Permanent::CrashedShipSite'        => {qty => 1, level => 28},

            'Waste::Sequestration'              => {qty => 2, level => 20},
            'Intelligence'                      => {qty => 1, level => 23},
            'Security'                          => {qty => 1, level => 23},
            'Espionage'                         => {qty => 1, level => 23},
            'CloakingLab'                       => {qty => 1, level => 23},
            'Propulsion'                        => {qty => 1, level => 25},
            'MunitionsLab'                      => {qty => 1, level => 20},
            'Shipyard'                          => {qty => 4, level => 29},
            'SpacePort'                         => {qty => 60,level => 26},
            'Observatory'                       => {qty => 1, level => 15},
            'Food::Burger'                      => {qty => 1, level => 15},
            'Food::Malcud'                      => {qty => 1, level => 15},
            'Food::Syrup'                       => {qty => 1, level => 10},
            'Waste::Digester'                   => {qty => 2, level => 15},
            'Energy::Singularity'               => {qty => 2, level => 15},
            'Archaeology'                       => {qty => 1, level => 20},
            'SAW'                               => {qty => 4, level => 10},
            'Waste::Exchanger'                  => {qty => 2, level => 15},
            'Trade'                             => {qty => 1, level => 25},
            'Transporter'                       => {qty => 1, level => 25},
            'Development'                       => {qty => 1, level => 15},

        },
        '30'   => {
            'Permanent::TheDillonForge'         => {qty => 1, level => 30},
            'Permanent::GasGiantPlatform'       => {qty => 4, level => 28},

            'Permanent::PyramidJunkSculpture'   => {qty => 1, level => 20},
            'Permanent::NaturalSpring'          => {qty => 1, level => 27},
            'Permanent::GeoThermalVent'         => {qty => 1, level => 28},
            'Permanent::AlgaePond'              => {qty => 1, level => 27},
            'Permanent::Volcano'                => {qty => 1, level => 26},
            'Permanent::InterDimensionalRift'   => {qty => 1, level => 28},
            'Permanent::CrashedShipSite'        => {qty => 1, level => 28},

            'Waste::Sequestration'              => {qty => 2, level => 20},
            'Intelligence'                      => {qty => 1, level => 27},
            'Security'                          => {qty => 1, level => 27},
            'Espionage'                         => {qty => 1, level => 27},
            'CloakingLab'                       => {qty => 1, level => 27},
            'Propulsion'                        => {qty => 1, level => 28},
            'MunitionsLab'                      => {qty => 1, level => 20},
            'Shipyard'                          => {qty => 4, level => 30},
            'SpacePort'                         => {qty => 70,level => 27},
            'Observatory'                       => {qty => 1, level => 15},
            'Food::Burger'                      => {qty => 1, level => 15},
            'Food::Malcud'                      => {qty => 1, level => 15},
            'Food::Syrup'                       => {qty => 1, level => 10},
            'Waste::Digester'                   => {qty => 2, level => 15},
            'Energy::Singularity'               => {qty => 2, level => 15},
            'Archaeology'                       => {qty => 1, level => 20},
            'SAW'                               => {qty => 4, level => 10},
            'Waste::Exchanger'                  => {qty => 2, level => 15},
            'Trade'                             => {qty => 1, level => 25},
            'Transporter'                       => {qty => 1, level => 25},
            'Development'                       => {qty => 1, level => 15},

        },
    };

    # All terrestrial planets are size 60 or below
    # All gas giants are size 70 or above
    #
    my $buildings = $db->resultset('Lacuna::DB::Result::Building');
    my $to_build = $has_buildings->{$level};

    foreach my $plan (keys %$to_build) {
        for (1..$to_build->{$plan}{qty}) {
            my ($x, $y) = $body->find_free_space;
            my $building = $buildings->new({
                class   => "Lacuna::DB::Result::Building::$plan",
                level   => $to_build->{$plan}{level} - 1,
                x       => $x,
                y       => $y,
                body_id => $body->id,
                body    => $body,
            });
            $body->build_building($building);
            $building->finish_upgrade;
        }
    }

    
}

