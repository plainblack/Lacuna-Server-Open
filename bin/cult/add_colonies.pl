use 5.010;
use strict;
use warnings;
use lib '/data/Lacuna-Server/lib';

use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date random_element);

use Getopt::Long;
use List::MoreUtils qw(uniq);
use Data::Dumper;

$|=1;
our $quiet      = 0; # omit output messages
our $respawn    = 0; # delete and respawn the empire

GetOptions(
    'quiet'      => \$quiet,  
    'respawn'    => \$respawn,
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

    $empire = $empires->find(-5);

    if (defined $empire) {
        out('Deleting existing empire');
        # First ensure we have demolished all glyph resource buildings
        for my $planet ($empire->planets->all) {
            out("Removing sensitive buildings from ".$planet->name);
            $planet->delete_buildings($planet->building_cache);
            out("Renaming");

            # Rename the planet 
            my $pname = $planet->star->name." ".$planet->orbit;
            my $orbit = 8;
            my $test;
            do {
                $test  = $db->resultset('Lacuna::DB::Result::Map::Body')->search({
                             name => $pname })->first;
                if ($test) {
                    $orbit++;
                    $pname = $planet->star->name." ".$orbit;
                }
            } while ($test);
            $planet->name($pname);
            $planet->update;
            out("Done with ".$planet->name);
        }

        $empire->delete;
    }
}

$empire = $empires->find(-5);
if (not defined $empire) {
    out('Creating new empire');
    $empire = create_empire();
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
        id                      => -5,
        name                    => 'Cult of the Fissure',
        stage                   => 'turing',
        date_created            => DateTime->now,
        status_message          => 'All is to be part of the Void.',
        description             => 'Break on thru to the other side',
        password                => Lacuna::DB::Result::Empire->encrypt_password(rand(99999999)),
        species_name            => 'cultists',
        species_description     => 'Only by releasing the fissures can we free ourselves',
        essentia                => 100,
        min_orbit               => 3,
        max_orbit               => 3,
        manufacturing_affinity  => 1, # cost of building new stuff
        deception_affinity      => 1, # spying ability
        research_affinity       => 1, # cost of upgrading
        management_affinity     => 1, # speed to build
        farming_affinity        => 1, # food
        mining_affinity         => 1, # minerals
        science_affinity        => 1, # energy, propultion, and other tech
        environmental_affinity  => 1, # waste and water
        political_affinity      => 1, # happiness
        trade_affinity          => 1, # speed of cargoships, and amount of cargo hauled
        growth_affinity         => 1, # price and speed of colony ships, and planetary command center start level
    });

    out('Find home planet...');
    my @bodies = $db->resultset('Map::Body')->search({
                        'me.empire_id'      => undef,
                        'stars.station_id'   => undef,
                        'me.class'          => { like => 'Lacuna::DB::Result::Map::Body::Planet::P%' },
                        'me.orbit'          => { between => [$empire->min_orbit, $empire->max_orbit] },
                 },{
                        join                => 'stars',
                        rows                => 100,
                        order_by            => 'me.name',
                   });
    my $home = random_element(\@bodies);

    $empire->insert;
    $home->delete_buildings($home->building_cache);
    $empire->found($home);
    $empire->university_level(30);
    $empire->update;
    create_colony($home);

    return $empire;
}


sub create_colony {
    my ($body) = @_;

    out("Creating Cult Colony on body ".$body->name);
    $body->name("Blue Oyster");
    $body->update;

    out('Upgrading PCC');
    my $pcc = $body->command;
    $pcc->level(30);
    $pcc->update;

    my $has_buildings = {
        'Waste::Sequestration' => {qty => 1, level => 30},
        'Intelligence'                    => {qty => 1, level => 20},
        'Security'                        => {qty => 1, level => 20},
        'Espionage'                       => {qty => 1, level => 20},
        'Shipyard'                        => {qty => 1, level => 10},
        'SpacePort'                       => {qty => 4, level => 20},
        'Observatory'                     => {qty => 1, level => 10},
        'Archaeology'                     => {qty => 1, level => 10},
        'Trade'                           => {qty => 1, level => 10},
        'SAW'                             => {qty => 6, level => 20},
        'Water::Storage'                  => {qty => 1, level => 30},
        'Ore::Storage'                    => {qty => 1, level => 30},
        'Energy::Reserve'                 => {qty => 1, level => 30},
        'Food::Reserve'                   => {qty => 1, level => 30},
        'Food::Corn'                      => {qty => 1, level => 15},
        'Food::Wheat'                     => {qty => 1, level => 15},
        'Food::Dairy'                     => {qty => 1, level => 15},
        'Permanent::Volcano'              => {qty => 1, level => 25},
        'Permanent::NaturalSpring'        => {qty => 1, level => 25},
        'Permanent::InterDimensionalRift' => {qty => 1, level => 25},
        'Permanent::GeoThermalVent'       => {qty => 1, level => 25},
        'Permanent::KalavianRuins'        => {qty => 1, level => 10},
        'Permanent::MalcudField'          => {qty => 1, level => 24},
        'Permanent::AlgaePond'            => {qty => 1, level => 24},
        'Permanent::BlackHoleGenerator'   => {qty => 1, level => 30},
        'Permanent::Ravine'               => {qty => 1, level => 30},
        'Permanent::TerraformingPlatform' => {qty => 5, level => 10},
    };

    my $buildings = $db->resultset('Lacuna::DB::Result::Building');
    my $to_build = $has_buildings;

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

