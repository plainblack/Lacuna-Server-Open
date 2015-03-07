use lib '../../lib';
use strict;
use 5.010;
use List::Util::WeightedChoice qw( choose_weighted );
use Lacuna;
use Lacuna::Util qw(randint);
use DateTime;
use Time::HiRes;

my $config = Lacuna->config;
my $db = Lacuna->db;
my $lacunans_have_been_placed = 0;

my $t = [Time::HiRes::tv_interval];
create_database();

# to test create db only, set env var, useful for testing db changes without
# rebuilding full star map, don't forget to change
# /data/Lacuna-Server/etc/lacuna.conf's db->dsn field to a new db first.
exit 0 if $ENV{CREATE_DB_ONLY};

open my $star_names, "<", "../../var/starnames.txt";
create_star_map();
close $star_names;
say "Time Elapsed: ".Time::HiRes::tv_interval($t);

sub create_database {
    $db->deploy({ add_drop_table => 1 });
}


sub create_star_map {
    my $map_size = $config->get('map_size');
    my ($start_x, $end_x) = @{$map_size->{x}};
    my ($start_y, $end_y) = @{$map_size->{y}};
    
    # account for orbits
    $start_x += 2;
    $start_y += 2;
    $end_x -= 2;
    $end_y -= 2;
    
    my @star_colors = (qw(magenta red green blue yellow white));
    my $made_lacuna = 0;
    say "Adding stars.";
    my $star_toggle = 1;
    my $real_y = $start_y;
    my $y;
    while ($real_y + 3 < $end_y) {
        say "Start Y $real_y";
        my $shim = ($star_toggle) ? randint(0,3) : randint(8,10);
        for (my $x = $start_x + $shim; $x < $end_x; $x += 15) {
            $y = $real_y + randint(0,3);
            say "Start X $x";            
            #if (rand(100) <= 15) { # 15% chance of no star
            if (0) {
                say "No star at $x, $y!";
            }
            else {
                my $name = get_star_name();
                if (!$made_lacuna && $x >= 0 && $y >= 0) {
                    $made_lacuna = 1;
                    $name = 'Lacuna';
                }
                say "Creating star $name at $x, $y.";
                my $star = $db->resultset('Lacuna::DB::Result::Map::Star')->new({
                    name        => $name,
                    color       => $star_colors[rand(scalar(@star_colors))],
                    x           => $x,
                    y           => $y,
                });
                $star->set_zone_from_xy;
                $star->insert;
                add_bodies($star);
            }
            say "End X $x";
        }
        $star_toggle = ($star_toggle) ? 0 : 1;
        say "End Y $y";
        $real_y += 5;
    }
}


sub add_bodies {
    my $star = shift;
    my @body_types = ('habitable', 'asteroid', 'gas giant');
    my @body_type_weights = (qw(70 10 10));
    my @planet_classes = qw(Lacuna::DB::Result::Map::Body::Planet::P1 Lacuna::DB::Result::Map::Body::Planet::P2 Lacuna::DB::Result::Map::Body::Planet::P3 Lacuna::DB::Result::Map::Body::Planet::P4
        Lacuna::DB::Result::Map::Body::Planet::P5 Lacuna::DB::Result::Map::Body::Planet::P6 Lacuna::DB::Result::Map::Body::Planet::P7 Lacuna::DB::Result::Map::Body::Planet::P8 Lacuna::DB::Result::Map::Body::Planet::P9
        Lacuna::DB::Result::Map::Body::Planet::P10 Lacuna::DB::Result::Map::Body::Planet::P11 Lacuna::DB::Result::Map::Body::Planet::P12 Lacuna::DB::Result::Map::Body::Planet::P13
        Lacuna::DB::Result::Map::Body::Planet::P14 Lacuna::DB::Result::Map::Body::Planet::P15 Lacuna::DB::Result::Map::Body::Planet::P16 Lacuna::DB::Result::Map::Body::Planet::P17
        Lacuna::DB::Result::Map::Body::Planet::P18 Lacuna::DB::Result::Map::Body::Planet::P19 Lacuna::DB::Result::Map::Body::Planet::P20);
    my @gas_giant_classes = qw(Lacuna::DB::Result::Map::Body::Planet::GasGiant::G1 Lacuna::DB::Result::Map::Body::Planet::GasGiant::G2 Lacuna::DB::Result::Map::Body::Planet::GasGiant::G3
        Lacuna::DB::Result::Map::Body::Planet::GasGiant::G4 Lacuna::DB::Result::Map::Body::Planet::GasGiant::G5);
    my @asteroid_classes = qw(Lacuna::DB::Result::Map::Body::Asteroid::A1 Lacuna::DB::Result::Map::Body::Asteroid::A2
        Lacuna::DB::Result::Map::Body::Asteroid::A3 Lacuna::DB::Result::Map::Body::Asteroid::A4
        Lacuna::DB::Result::Map::Body::Asteroid::A5 Lacuna::DB::Result::Map::Body::Asteroid::A6
        Lacuna::DB::Result::Map::Body::Asteroid::A7 Lacuna::DB::Result::Map::Body::Asteroid::A8
        Lacuna::DB::Result::Map::Body::Asteroid::A9 Lacuna::DB::Result::Map::Body::Asteroid::A10
        Lacuna::DB::Result::Map::Body::Asteroid::A11 Lacuna::DB::Result::Map::Body::Asteroid::A12
        Lacuna::DB::Result::Map::Body::Asteroid::A13 Lacuna::DB::Result::Map::Body::Asteroid::A14
        Lacuna::DB::Result::Map::Body::Asteroid::A15 Lacuna::DB::Result::Map::Body::Asteroid::A16
        Lacuna::DB::Result::Map::Body::Asteroid::A17 Lacuna::DB::Result::Map::Body::Asteroid::A18
        Lacuna::DB::Result::Map::Body::Asteroid::A19 Lacuna::DB::Result::Map::Body::Asteroid::A20 Lacuna::DB::Result::Map::Body::Asteroid::A21
        );
    say "\tAdding bodies.";
    for my $orbit (1..8) {
        my $name = $star->name." ".$orbit;
        if (randint(1,100) <= 10) { # 10% chance of no body in an orbit
            say "\tNo body at $name!";
        } 
        else {
            my ($x, $y);
            if ($orbit == 1) {
                $x = $star->x + 1; $y = $star->y + 2;
            }
            elsif ($orbit == 2) {
                $x = $star->x + 2; $y = $star->y + 1;
            }
            elsif ($orbit == 3) {
                $x = $star->x + 2; $y = $star->y - 1;
            }
            elsif ($orbit == 4) {
                $x = $star->x + 1; $y = $star->y - 2;
            }
            elsif ($orbit == 5) {
                $x = $star->x - 1; $y = $star->y - 2;
            }
            elsif ($orbit == 6) {
                $x = $star->x - 2; $y = $star->y - 1;
            }
            elsif ($orbit == 7) {
                $x = $star->x - 2; $y = $star->y + 1;
            }
            elsif ($orbit == 8) {
                $x = $star->x - 1; $y = $star->y + 2;
            }
            my $type = ($orbit == 3) ? 'habitable' : choose_weighted(\@body_types, \@body_type_weights); # orbit 3 should always be habitable
            say "\tAdding a $type at $name (".$x.",".$y.").";
            my $params = {
                name                => $name,
                orbit               => $orbit,
                x                   => $x,
                y                   => $y,
                star_id             => $star->id,
                zone                => $star->zone,
                usable_as_starter   => 0,
                usable_as_starter_enabled => 0,
            };
            my $body;
            if ($type eq 'habitable') {
                $params->{class} = $planet_classes[rand(scalar(@planet_classes))];
                $params->{size} = ($params->{orbit} == 3) ? randint(35,55) : randint(30,60);
                if ($params->{size} >= 40 && $params->{size} <= 50) {
                    $params->{usable_as_starter} = randint(8000,9000) + ($params->{size} * 10) - abs($params->{y}) - abs($params->{x});
                    $params->{usable_as_starter_enabled} = 1;
                }
            }
            elsif ($type eq 'asteroid') {
                $params->{class} = $asteroid_classes[rand(scalar(@asteroid_classes))];
                $params->{size} = randint(1,10);
            }
            else {
                $params->{class} = $gas_giant_classes[rand(scalar(@gas_giant_classes))];
                $params->{size} = randint(70,121);
            }
            $body = $db->resultset('Lacuna::DB::Result::Map::Body')->new($params);
            $body->insert;
            if ($body->isa('Lacuna::DB::Result::Map::Body::Planet') && !$body->isa('Lacuna::DB::Result::Map::Body::Planet::GasGiant')) {
                if ($star->name eq 'Lacuna' && !$lacunans_have_been_placed) {
                    create_lacunan_home_world($body);
                    next;
                }
                else {
                    add_features($body);
                }
            }
        }
    }
}

sub add_features {
    my $body = shift;
    say "\t\tAdding features to body.";
    my $now = DateTime->now;
    foreach  my $x (-3, -1, 2, 4, 1) {
        my $chance = randint(1,100);
        my $y = randint(-5,5);
        if ($chance <= 5) {
            say "\t\t\tAdding lake.";
            $db->resultset('Lacuna::DB::Result::Building')->new({
                date_created    => $now,
                level           => 1,
                x               => $x,
                y               => $y,
                class           => 'Lacuna::DB::Result::Building::Permanent::Lake',
                body_id         => $body->id,
            })->insert;
        }
        elsif ($chance > 45 && $chance <= 50) {
            say "\t\t\tAdding rocky outcropping.";
            $db->resultset('Lacuna::DB::Result::Building')->new({
                date_created    => $now,
                level           => 1,
                x               => $x,
                y               => $y,
                class           => 'Lacuna::DB::Result::Building::Permanent::RockyOutcrop',
                body_id         => $body->id,
            })->insert;
        }
        elsif ($chance > 95) {
            say "\t\t\tAdding crater.";
            $db->resultset('Lacuna::DB::Result::Building')->new({
                date_created    => $now,
                level           => 1,
                x               => $x,
                y               => $y,
                class           => 'Lacuna::DB::Result::Building::Permanent::Crater',
                body_id         => $body->id,
            })->insert;
        }
    }
}


sub create_lacunan_home_world {
    my $body = shift;
    $body->update({name=>'Lacuna'});
    say "\t\t\tMaking this the Lacunans home world.";
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->new({
        id                  => 1,
        name                => 'Lacuna Expanse Corp',
        date_created        => DateTime->now,
        stage               => 'founded',
        status_message      => 'Will trade for Essentia.',
        password            => Lacuna::DB::Result::Empire->encrypt_password(rand(99999999)),
        species_name            => 'Lacunan',
        species_description     => 'The economic dieties that control the Lacuna Expanse.',
        min_orbit               => 1,
        max_orbit               => 7,
        manufacturing_affinity  => 1, # cost of building new stuff
        deception_affinity      => 7, # spying ability
        research_affinity       => 1, # cost of upgrading
        management_affinity     => 4, # speed to build
        farming_affinity        => 1, # food
        mining_affinity         => 1, # minerals
        science_affinity        => 1, # energy, propultion, and other tech
        environmental_affinity  => 1, # waste and water
        political_affinity      => 7, # happiness
        trade_affinity          => 7, # speed of cargoships, and amount of cargo hauled
        growth_affinity         => 7, # price and speed of colony ships, and planetary command center start level
    });
    $empire->insert;
    $empire->found($body);
    $lacunans_have_been_placed = 1;    
}



sub get_star_name {
    my $name = <$star_names>;
    chomp $name;
    return $name;
}

