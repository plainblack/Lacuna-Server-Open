use lib '../lib';
use strict;
use 5.010;
use List::Util::WeightedChoice qw( choose_weighted );
use Lacuna;
use Lacuna::Util qw(randint);
use DateTime;

my $config = Lacuna->config;
my $db = Lacuna::DB->new(access_key=>$config->get('access_key'), secret_key=>$config->get('secret_key'), cache_servers=>$config->get('memcached'));
my $lacunans;
my $lacunans_have_been_placed = 0;


create_species();
create_aux_domains();
open my $star_names, "<", "../var/starnames.txt";
create_star_map();
close $star_names;

sub create_aux_domains {
    foreach my $name (qw(empire session build_queue message travel_queue news spies ship_builds)) {
        my $domain = $db->domain($name);
        say "Deleting existing $name domain.";
        $domain->delete;
        say "Creating new $name domain.";
        $domain->create;
    }
}

sub create_species {
    my $species = $db->domain('species');
    say "Deleting existing species domain.";
    $species->delete;
    say "Creating new species domain.";
    $species->create;
    say "Adding humans.";
    $species->insert({
        name                    => 'Human',
        description             => 'A race of average intellect, and weak constitution.',
        habitable_orbits        => [3],
        manufacturing_affinity   => 4, # cost of building new stuff
        deception_affinity      => 4, # spying ability
        research_affinity       => 4, # cost of upgrading
        management_affinity     => 4, # speed to build
        farming_affinity        => 4, # food
        mining_affinity         => 4, # minerals
        science_affinity        => 4, # energy, propultion, and other tech
        environmental_affinity  => 4, # waste and water
        political_affinity      => 4, # happiness
        trade_affinity          => 4, # speed of cargoships, and amount of cargo hauled
        growth_affinity         => 4, # price and speed of colony ships, and planetary command center start level
    }, id=>'human_species');
    say "Adding Lacunans.";
    $lacunans = $species->insert({
        name                    => 'Lacunan',
        description             => 'The economic dieties that control the Lacuna Expanse.',
        habitable_orbits        => [1,2,3,4,5,6,7],
        manufacturing_affinity   => 1, # cost of building new stuff
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
    }, id=>'lacunan_species');
}


sub create_star_map {
    my $map_size = $config->get('map_size');
    my ($start_x, $end_x) = @{$map_size->{x}};
    my ($start_y, $end_y) = @{$map_size->{y}};
    my ($start_z, $end_z) = @{$map_size->{z}};
    my $star_count = abs($end_x - $start_x) * abs($end_y - $start_y) * abs($end_z - $start_z);
    my @star_colors = (qw(magenta red green blue yellow white));
    my %domains;
    foreach my $domain (qw(star body ore water building waste energy food permanent)) {
        $domains{$domain} = $db->domain($domain);
        say "Deleting existing $domain domain.";
        $domains{$domain}->delete;
        say "Create new $domain domain.";
        $domains{$domain}->create;
    }

    my $made_lacuna = 0;
    say "Adding stars.";
    for my $x ($start_x .. $end_x) {
        say "Start X $x";
        for my $y ($start_y .. $end_y) {
            say "Start Y $y";
            for my $z ($start_z .. $end_z) {
                say "Start Z $z";
                if (rand(100) <= 15) { # 15% chance of no star
                    say "No star at $x, $y, $z!";
                }
                else {
                    my $name = get_star_name();
                    if (!$made_lacuna && $x >= 0 && $y >= 0 && $z >= 0) {
                        $made_lacuna = 1;
                        $name = 'Lacuna';
                    }
                    say "Creating star $name at $x, $y, $z.";
                    my $star = Lacuna::DB::Star->new(
                        simpledb    => $db,
                        name        => $name,
                        date_created=> DateTime->now,
                        color       => $star_colors[rand(scalar(@star_colors))],
                        x           => $x,
                        y           => $y,
                        z           => $z,
                    );
                    $star->set_zone_from_xyz;
                    $star->put;
                    add_bodies(\%domains, $star);
                }
                say "End Z $z";
            }
            say "End Y $y";
        }
        say "End X $x";
    }
}


sub add_bodies {
    my $domains = shift;
    my $star = shift;
    my @body_types = ('habitable', 'asteroid', 'gas giant');
    my @body_type_weights = (qw(60 15 15));
    my @planet_classes = qw(Lacuna::DB::Body::Planet::P1 Lacuna::DB::Body::Planet::P2 Lacuna::DB::Body::Planet::P3 Lacuna::DB::Body::Planet::P4
        Lacuna::DB::Body::Planet::P5 Lacuna::DB::Body::Planet::P6 Lacuna::DB::Body::Planet::P7 Lacuna::DB::Body::Planet::P8 Lacuna::DB::Body::Planet::P9
        Lacuna::DB::Body::Planet::P10 Lacuna::DB::Body::Planet::P11 Lacuna::DB::Body::Planet::P12 Lacuna::DB::Body::Planet::P13
        Lacuna::DB::Body::Planet::P14 Lacuna::DB::Body::Planet::P15 Lacuna::DB::Body::Planet::P16 Lacuna::DB::Body::Planet::P17
        Lacuna::DB::Body::Planet::P18 Lacuna::DB::Body::Planet::P19 Lacuna::DB::Body::Planet::P20);
    my @gas_giant_classes = qw(Lacuna::DB::Body::Planet::GasGiant::G1 Lacuna::DB::Body::Planet::GasGiant::G2 Lacuna::DB::Body::Planet::GasGiant::G3
        Lacuna::DB::Body::Planet::GasGiant::G4 Lacuna::DB::Body::Planet::GasGiant::G5);
    my @asteroid_classes = qw(Lacuna::DB::Body::Asteroid::A1 Lacuna::DB::Body::Asteroid::A2 Lacuna::DB::Body::Asteroid::A3
        Lacuna::DB::Body::Asteroid::A4 Lacuna::DB::Body::Asteroid::A5);
    say "\tAdding bodies.";
    for my $orbit (1..7) {
        my $name = $star->name." ".$orbit;
        if (randint(1,100) <= 10) { # 10% chance of no body in an orbit
            say "\tNo body at $name!";
        } 
        else {
            my $type = ($orbit == 3) ? 'habitable' : choose_weighted(\@body_types, \@body_type_weights); # orbit 3 should always be habitable
            say "\tAdding a $type at $name (".$star->x.",".$star->y.",".$star->z.").";
            my $params = {
                name                => $name,
                orbit               => $orbit,
                x                   => $star->x,
                y                   => $star->y,
                z                   => $star->z,
                star_id             => $star->id,
                usable_as_starter   => 'No',
                zone                => $star->zone,
            };
            if ($type eq 'habitable') {
                $params->{class} = $planet_classes[rand(scalar(@planet_classes))];
                $params->{empire_id} = 'None';
                $params->{size} = ($params->{orbit} == 3) ? randint(45,60) : randint(25,85);
                $params->{usable_as_starter} = ($params->{size} >= 47 && $params->{size} <= 56) ? rand(99999) : 'No';
            }
            elsif ($type eq 'asteroid') {
                $params->{class} = $asteroid_classes[rand(scalar(@asteroid_classes))];
                $params->{size} = randint(1,10);
            }
            else {
                $params->{class} = $gas_giant_classes[rand(scalar(@gas_giant_classes))];
                $params->{empire_id} = 'None';
                $params->{size} = randint(70,121);
            }
            my $body = $domains->{body}->insert($params);
            my $now = DateTime->now;
            if ($body->isa('Lacuna::DB::Body::Planet') && !$body->isa('Lacuna::DB::Body::Planet::GasGiant')) {
                if ($star->name eq 'Lacuna' && !$lacunans_have_been_placed) {
                    $body->name('Lacuna');
                    $body->put;
                    create_lacuna_corp($body, $domains);
                    $lacunans_have_been_placed = 1;
                    next;
                }
                say "\t\tAdding features to body.";
                foreach  my $x (-3, -1, 2, 4, 1) {
                    my $chance = randint(1,100);
                    my $y = randint(-5,5);
                    if ($chance <= 5) {
                        say "\t\t\tAdding lake.";
                        $domains->{permanent}->insert({
                            date_created    => $now,
                            level           => 1,
                            x               => $x,
                            y               => $y,
                            class           => 'Lacuna::DB::Building::Permanent::Lake',
                            body_id         => $body->id,
                        });
                    }
                    elsif ($chance > 45 && $chance <= 50) {
                        say "\t\t\tAdding rocky outcropping.";
                        $domains->{permanent}->insert({
                            date_created    => $now,
                            level           => 1,
                            x               => $x,
                            y               => $y,
                            class           => 'Lacuna::DB::Building::Permanent::RockyOutcrop',
                            body_id         => $body->id,
                        });
                    }
                    elsif ($chance > 95) {
                        say "\t\t\tAdding crater.";
                        $domains->{permanent}->insert({
                            date_created    => $now,
                            level           => 1,
                            x               => $x,
                            y               => $y,
                            class           => 'Lacuna::DB::Building::Permanent::Crater',
                            body_id         => $body->id,
                        });
                    }
                }
            }
        }
    }
}

sub create_lacuna_corp {
    my ($body, $domains) = @_;
    say "\t\t\tMaking this the Lacunans home world.";
    my $empire = Lacuna::DB::Empire->create(
        $db,
        {name=>'Lacuna Expanse Corp', password=>rand(9999999)},
        'lacuna_expanse_corp'
        );
    $empire->species_id($lacunans->id);
    $empire->put;
    $empire->found($body)
}

sub get_star_name {
    my $name = <$star_names>;
    chomp $name;
    return $name;
}

