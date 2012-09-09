use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Data::Dumper;
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);


out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

out('Ticking fissures');
my %has_fissures = map { $_->body_id => 1 } $db->resultset('Building')->search({
    class => 'Lacuna::DB::Result::Building::Permanent::Fissure',
    })->all;

for my $body_id (sort keys %has_fissures) {
    my $body = $db->resultset('Map::Body')->find($body_id);
    out('Ticking Fissures on '.$body->name);
    my @fissures = $body->get_buildings_of_class('Lacuna::DB::Result::Building::Permanent::Fissure');

    # Decrease the % efficiency of all Fissure containment systems.
    # If a Fissure reaches 0% then it becomes unstable and upgrades a level and resets to 100% efficiency
    # When upgrading, it causes up to 10% damage to all energy producing buildings
    # When there is one Fissure at level 30 and 0% containment efficiency then another is spawned
    # When there are two Fissures at level 30 and 0% containment efficiency then the planet implodes.
    # When a new fissure is spawned, it first targets a BHG, then energy singularity, then any energy building
    #   and finally a spare space or a building at random (excluding the PCC).
    # The level of the second Fissure is the same level as the BHG (if there is one) otherwise it is level 1
    #
    for my $fissure (@fissures) {
        out("Fissure at ".$fissure->x.",".$fissure->y." co-ordinates");
        if ($fissure->efficiency > 0) {
            $fissure->efficiency($fissure->efficiency - 4);
        }
        if ($fissure->efficiency <= 0) {
            $fissure->efficiency(0);
            if ($fissure->level < 30) {
                $fissure->level($fissure->level + 1);
                $fissure->efficiency(100);
                # damage energy buildings.
                
            }
        }
        out("    set to ".$fissure->efficiency."% containment efficiency");
        $fissure->is_working(0);
        $fissure->update;
    }

    # get number of Fissures at 0% efficiency and maximum level
    my $max_fissures = grep { $_->efficiency == 0 and $_->level == 30 } @fissures;
    if ($max_fissures == @fissures) {
        if ($max_fissures == 1) {
            out("    adding a second fissure!!!");
            # Then add a second fissure
            # If there is a BHG then convert that!
            my $building = $body->get_building_of_class("Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator");
            my $fissure_level = 1;
            if ($building) {
                out("    using the existing BHG");
                my $now = DateTime->now;
                $building->class('Lacuna::DB::Result::Building::Permanent::Fissure');
                if ($building->is_working) {
                    $building->is_working(0);
                    $building->work_ends($now);
                }
                $building->is_upgrading(0);
                $building->efficiency(100);
                $building->update;
                $fissure_level = $building->level;
            }
            else {
                # First locate all energy buildings.
                my @energy_buildings = qw(Singularity Fusion Fission Hydrocarbon Geo Reserve);
                BUILDING:
                for my $energy_bld (@energy_buildings) {
                    if ($building = $body->get_building_of_class("Lacuna::DB::Result::Building::Energy::$energy_bld")) {
                        out("    Using the existing $energy_bld building!");
                        last BUILDING;
                    }
                }
                if (not $building) {
                    # then any random building (except the PCC)
                    my @buildings = grep {
                            ($_->x != 0 or $_->y != 0)            # anything except the PCC
                        and ($_->class != 'Lacuna::DB::Result::Building::Permanent::Fissure')   # Not a Fissure!
                        and ($_->class != 'Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator"')
                    } @{$body->building_cache};
                    $building = random_element(@buildings);                                       
                    out("    Using the existing ".$building->class." building!");
                }
                if (not $building) {
                    # then any free space
                    my $x = randint(-5,5);
                    my $y = randint(-5,5);
                    if ($x == 0 and $y == 0) {
                        $x = 1;
                    }
                    out("    Output on free plot $x,$y");
                    $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
                        x       => $x,
                        y       => $y,
                        class   => 'Lacuna::DB::Result::Building::Permanent::Fissure',
                        level   => $fissure_level - 1,
                    });
                    $body->build_building($building);
                    $building->finish_upgrade;
                }
                $building->update({
                    level       => $fissure_level,
                    class       => 'Lacuna::DB::Result::Building::Permanent::Fissure',
                    efficiency  => 100,
                    available   => DateTime->now,
                    is_working  => 0,
                });
                out("    Created a level ".$building->level." Fissure");
            }
        }
        else {
            # If it is an empire.
            if ($body->empire_id) {
                my $empire = $body->empire;

                # Send the empire an email

                # If it is the empires home world
                if ($body->id == $empire->home_planet_id) {
                    # check if there are other colonies we can move the capitol to
                    
                    # if so, then move the capitol
                    
                    # else find a new, remote colony and found it

                    # Send an email with the new co-ordinates

                    # Put something on N19
                }
                else {
                    # else it is 'just' a colony

                    # Send an email about the destruction

                    # Put something on N19
                }
            }
            # demolish the planet

 
        }
    }
}

###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


