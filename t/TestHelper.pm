package TestHelper;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Lacuna::DB;
use Lacuna;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Data::Dumper;
use 5.010;
use Test::More;

has ua => (
    is  => 'ro',
    lazy => 1,
    default => sub {  my $ua = LWP::UserAgent->new; $ua->timeout(30); return $ua; },
);

has empire_name => (
    is => 'ro',
    default => 'TLE Test Empire',
);

has empire_password => (
    is => 'ro',
    default => '123qwe',
);

has empire => (
    is  => 'rw',
    lazy => 1,
    default => sub { my $self = shift; return Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name=>$self->empire_name})->first; },
);

has session => (
    is => 'rw',
    );

has x => (
    is => 'rw',
    default => -5,
);

has y => (
    is => 'rw',
    default => -5,
);

has big_producer => (
    is => 'rw',
    default => 0,
);

sub clear_all_test_empires {
    my ($class, $name) = @_;

    $name = 'TLE Test%' unless $name;

    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({
        name => {like => $name},
    });
    while (my $empire = $empires->next) {
        $empire->essentia_game(0);
        $empire->essentia_free(0);
        $empire->essentia_paid(0);
        $empire->update;

        my $planets = $empire->planets;
        while ( my $planet = $planets->next ) {
            my @buildings = grep {$_->class =~ /Permanent/} @{$planet->building_cache};
            $planet->delete_buildings(\@buildings);
        }

        $empire->delete;
    }
}

sub use_existing_test_empire {
    my ($self) = @_;

    my ($empire) = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({
        name => $self->empire_name,
    });
    if (not $empire) {
        $self->generate_test_empire;
        my $home = $self->empire->home_planet;
        $self->build_big_colony($home);
        $empire = $self->empire;
    }
    $self->session($empire->start_session({api_key => 'tester'}));
    $self->empire($empire);
    return $self;
}

sub generate_test_empire {
    my $self = shift;
    # Make sure no other test empires are still around
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({
        name                => $self->empire_name,
    });
    while (my $empire = $empires->next) {
        $empire->delete;
    }


    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->new({
        name                => $self->empire_name,
        date_created        => DateTime->now,
        status_message      => 'Making Lacuna a better Expanse.',
        password            => Lacuna::DB::Result::Empire->encrypt_password($self->empire_password),
    })->insert;
    $empire->found;
    $self->session($empire->start_session({api_key => 'tester'}));
    $self->empire($empire);
    return $self;
}

sub get_building { 
    my ($self, $building_id) = @_;

    $self->empire->home_planet->clear_building_cache;

    my ($building) = grep {$_->id == $building_id} @{$self->empire->home_planet->building_cache};
    unless (defined $building) {
        confess 'Building does not exist.';
    }
    return $building;
}

sub find_empty_plot {
     my ($self) = @_;

     my $home = $self->empire->home_planet;

     # Ensure we only build on an empty plot
     EXISTING_BUILDING:
     while (1) {
        my ($building) = grep {$_->x == $self->x and $_->y == $self->y} @{$home->building_cache};

          last EXISTING_BUILDING if not $building;
          $self->x($self->x + 1);
          if ($self->x == 6) {
               $self->x(-5);
               $self->y($self->y + 1);
          }
     }
}

sub build_building {
    my ($self, $class, $level) = @_;

    my $home = $self->empire->home_planet;
    $self->find_empty_plot;

    my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        x               => $self->x,
        y               => $self->y,
        class           => $class,
        level           => $level - 1,
    });
    $home->build_building($building);
    $building->finish_upgrade;
    return $building;
}

sub build_infrastructure {
    my $self = shift;
    my $home = $self->empire->home_planet;
    foreach my $type ('Lacuna::DB::Result::Building::Food::Algae','Lacuna::DB::Result::Building::Energy::Hydrocarbon',
        'Lacuna::DB::Result::Building::Water::Purification','Lacuna::DB::Result::Building::Water::Purification','Lacuna::DB::Result::Building::Water::Purification','Lacuna::DB::Result::Building::Ore::Mine','Lacuna::DB::Result::Building::Ore::Mine','Lacuna::DB::Result::Building::Ore::Mine','Lacuna::DB::Result::Building::Food::Algae','Lacuna::DB::Result::Building::Food::Algae','Lacuna::DB::Result::Building::Energy::Hydrocarbon','Lacuna::DB::Result::Building::Energy::Hydrocarbon') {

        $self->build_building($type, 20);
    }
    $home->empire->university_level(30);
    $home->empire->update;
    foreach my $type ('Lacuna::DB::Result::Building::Energy::Reserve',
        'Lacuna::DB::Result::Building::Food::Reserve','Lacuna::DB::Result::Building::Ore::Storage',
        'Lacuna::DB::Result::Building::Water::Storage') {

        $self->build_building($type, 20);

    }

    if ($self->big_producer) {
        $home->ore_hour(50000000);
        $home->water_hour(50000000);
        $home->energy_hour(50000000);
        $home->algae_production_hour(50000000);
        $home->ore_capacity(50000000);
        $home->energy_capacity(50000000);
        $home->food_capacity(50000000);
        $home->water_capacity(50000000);
        $home->bauxite_stored(50000000);
        $home->algae_stored(50000000);
        $home->energy_stored(50000000);
        $home->water_stored(50000000);
        $home->add_happiness(50000000);
        $home->monazite_stored(5000000);
    }
    else {
        $home->algae_stored(100_000);
        $home->bauxite_stored(100_000);
        $home->energy_stored(100_000);
        $home->water_stored(100_000);
    }

    $home->tick;
    return $self;
}

sub post {
    my ($self, $url, $method, $params) = @_;
    my $content = {
        jsonrpc     => '2.0',
        id          => 1,
        method      => $method,
        params      => $params,
    };
    say "REQUEST: ".to_json($content);
    my $response = $self->ua->post(Lacuna->config->get('server_url').$url,
        Content_Type    => 'application/json',
        Content         => to_json($content),
        Accept          => 'application/json',
        );
    say "RESPONSE: ".$response->content;
    sleep 2;
    return from_json($response->content);
}

sub cleanup {
    my $self = shift;
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name=>$self->empire_name});
    while (my $empire = $empires->next) {
        # delete any permanent buildings
        
        my $planets = $empire->planets;
        while ( my $planet = $planets->next ) {
            my @buildings = grep {$_->class =~ /Permanent/} @{$planet->building_cache};
            $planet->delete_buildings(\@buildings);
        }

        $empire->delete;
    }
}

sub finish_ships {
	my ( $self, $shipyard_id ) = @_;
	my $finish = DateTime->now;

	Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({shipyard_id=>$shipyard_id})->update({date_available=>$finish, task=>'Docked'});
}

sub build_big_colony {
    my ($self, $planet) = @_;

    my $empire = $planet->empire;
    $planet->delete_buildings(@{$planet->building_cache});
    $planet->ships->delete_all;
    Lacuna->db->resultset('Spies')->search({from_body_id => $planet->id})->delete_all;

    my $layout = {
        'PlanetaryCommand' => [
            { x => 0, y => 0, level => 30 },
        ],
        'SpacePort' => [
            { x => -2, y => -2, level => 22 },
            { x => -1, y => -2, level => 22 },
            { x =>  0, y => -2, level => 22 },
            { x =>  1, y => -2, level => 22 },
            { x =>  2, y => -2, level => 22 },
            { x => -2, y => -1, level => 22 },
            { x => -1, y => -1, level => 22 },
            { x =>  0, y => -1, level => 22 },
            { x =>  1, y => -1, level => 22 },
            { x =>  2, y => -1, level => 22 },
            { x => -2, y =>  0, level => 22 },
            { x => -1, y =>  0, level => 22 },
            { x =>  1, y =>  0, level => 22 },
            { x =>  2, y =>  0, level => 22 },
            { x => -2, y =>  1, level => 22 },
            { x => -1, y =>  1, level => 22 },
            { x =>  0, y =>  1, level => 22 },
            { x =>  1, y =>  1, level => 22 },
            { x =>  2, y =>  1, level => 22 },
            { x => -2, y =>  2, level => 22 },
            { x => -1, y =>  2, level => 22 },
            { x =>  0, y =>  2, level => 22 },
            { x =>  1, y =>  2, level => 22 },
            { x =>  2, y =>  2, level => 22 },
            { x =>  4, y =>  -4, level => 22 },
            { x =>  4, y =>  -3, level => 22 },
            { x =>  4, y =>  -2, level => 22 },
            { x =>  4, y =>  -1, level => 22 },
            { x =>  4, y =>  0, level => 22 },
            { x =>  4, y =>  1, level => 22 },
            { x =>  4, y =>  2, level => 22 },
            { x =>  4, y =>  3, level => 22 },
            { x =>  4, y =>  4, level => 22 },
            { x =>  -4, y =>  -4, level => 22 },
            { x =>  -4, y =>  -3, level => 22 },
            { x =>  -4, y =>  -2, level => 22 },
            { x =>  -4, y =>  -1, level => 22 },
            { x =>  -4, y =>  0, level => 22 },
            { x =>  -4, y =>  1, level => 22 },
            { x =>  -4, y =>  2, level => 22 },
            { x =>  -4, y =>  3, level => 22 },
            { x =>  -4, y =>  4, level => 22 },
            { x =>  -3, y =>  -4, level => 22 },
            { x =>  -2, y =>  -4, level => 22 },
            { x =>  -1, y =>  -4, level => 22 },
            { x =>  0, y =>  -4, level => 22 },
            { x =>  1, y =>  -4, level => 22 },
            { x =>  2, y =>  -4, level => 22 },
            { x =>  3, y =>  -4, level => 22 },
            { x =>  -3, y =>  4, level => 22 },
            { x =>  -2, y =>  4, level => 22 },
            { x =>  -1, y =>  4, level => 22 },
            { x =>  0, y =>  4, level => 22 },
            { x =>  1, y =>  4, level => 22 },
            { x =>  2, y =>  4, level => 22 },
            { x =>  3, y =>  4, level => 22 },
        ],
        'Permanent::Volcano' => [ { x => 1, y => -3, level => 30 }, ],
        'Permanent::InterDimensionalRift' => [ { x => 2, y => -3, level => 30 }, ],
        'Archaeology' => [ { x => 3, y => -3, level => 30 }, ],
        'Development' => [ { x => 0, y => -3, level => 30 }, ],
        'Permanent::GeoThermalVent' => [ { x => -1, y => -3, level => 30 }, ],
        'Espionage' => [ { x => -2, y => -3, level => 30 }, ],
        'Security' => [ { x => -3, y => -3, level => 30 }, ],
        'Intelligence' => [ { x => -3, y => -2, level => 30 }, ],
        'Embassy' => [ { x => -3, y => 0, level => 30 }, ],
        'Trade' => [ { x => 0, y => 3, level => 30 }, ],
        'Transporter' => [ { x => 3, y => 0, level => 30 }, ],
        'University' => [ { x => 3, y => -1, level => 30 }, ],
        'Observatory' => [ { x => 3, y => -2, level => 30 }, ],
        'TheftTraining' => [ { x => -3, y => 1, level => 30 }, ],
        'IntelTraining' => [ { x => -3, y => 2, level => 30 }, ],
        'MayhemTraining' => [ { x => -3, y => 3, level => 30 }, ],
        'PoliticsTraining' => [ { x => -2, y => 3, level => 30 }, ],
        'Permanent::NaturalSpring' => [ { x => -1, y => 3, level => 30 }, ],
        'Permanent::CrashedShipSite' => [ { x => 1, y => 3, level => 30 }, ],
        'CloakingLab' => [ { x => 2, y => 3, level => 30 }, ],
        'MunitionsLab' => [ { x => 3, y => 3, level => 30 }, ],
        'PilotTraining' => [ { x => 3, y => 2, level => 30 }, ],
        'Propulsion' => [ { x => 3, y => 1, level => 30 }, ],
        'Permanent::DentonBrambles' => [ { x => -5, y => 2, level => 30 }, ],
        'Permanent::AlgaePond' => [ { x => -5, y => 1, level => 30 }, ],
        'MercenariesGuild' => [ { x => -3, y => -1, level => 30 }, ],
        'Permanent::SpaceJunkPark' => [ { x => -5, y => -1, level => 30 }, ],
        'Permanent::PyramidJunkSculpture' => [ { x => -5, y => -2, level => 30 }, ],
        'Permanent::GratchsGauntlet' => [ { x => 5, y => 2, level => 30 }, ],
        'Permanent::Ravine' => [ { x => 5, y => 1, level => 30 }, ],
        'Permanent::JunkHengeSculpture' => [ { x => 5, y => -1, level => 30 }, ],
        'Permanent::MetalJunkArches' => [ { x => 5, y => -2, level => 30 }, ],
        'Permanent::GasGiantPlatform' => [
            { x =>  5, y =>  5, level => 30 },
            { x =>  5, y =>  -5, level => 30 },
            { x =>  -5, y =>  5, level => 30 },
            { x =>  -5, y =>  -5, level => 30 },
        ],
        'Shipyard' => [
            { x =>  -2, y =>  5, level => 30 },
            { x =>  -1, y =>  5, level => 30 },
            { x =>  1, y =>  5, level => 30 },
            { x =>  2, y =>  5, level => 30 },
            { x =>  -2, y =>  -5, level => 30 },
            { x =>  -1, y =>  -5, level => 30 },
            { x =>  1, y =>  -5, level => 30 },
            { x =>  2, y =>  -5, level => 30 },
        ],
        'SAW' => [
            { x =>  -4, y =>  5, level => 30 },
            { x =>   4, y =>  5, level => 30 },
            { x =>  -4, y =>  -5, level => 30 },
            { x =>   4, y =>  -5, level => 30 },
            { x =>  -5, y =>  4, level => 30 },
            { x =>   5, y =>  4, level => 30 },
            { x =>  -5, y =>  -4, level => 30 },
            { x =>   5, y =>  -4, level => 30 },
            { x =>   0, y =>  5, level => 30 },
            { x =>   0, y =>  -5, level => 30 },
        ],
    };

    diag("Generating buildings");
    for my $class (keys %$layout ) {
        for my $location (@{$layout->{$class}}) {
            my $building = Lacuna->db->resultset('Building')->new({
                x               => $location->{x},
                y               => $location->{y},
                class           => "Lacuna::DB::Result::Building::$class",
                level           => $location->{level} - 1,
            });
            $planet->build_building($building);
            $building->finish_upgrade;
        }
    }
    $planet->bauxite_stored(19,000,000,000);
    $planet->algae_stored(19,000,000,000);
    $planet->energy_stored(19,000,000,000);
    $planet->water_stored(19,000,000,000);
    $planet->needs_recalc(1);
    $planet->update;
    $planet->tick;

    my ($shipyard) = grep {$_->class eq 'Lacuna::DB::Result::Building::Shipyard'} @{$planet->building_cache};
    diag("Generating ships [".$self->session->id."][".$shipyard->id."]");
    my $ships = {
        excavator               => 30,
        probe                   => 20,
        sweeper                 => 1300,
        fighter                 => 500,
        hulk                    => 250,
        detonator               => 20,
        security_ministry_seeker=> 20,
        smuggler_ship           => 20,
        snark3                  => 200,
        spy_pod                 => 20,
        spy_shuttle             => 20,
        supply_pod4             => 10,

    };
    for my $ship (keys %$ships) {
        my $result = $self->post('shipyard', 'build_ship', [$self->session->id, $shipyard->id, $ship]);
        $self->finish_ships( $shipyard->id );
        if ($ships->{$ship} > 1) {
            my $ship_id = $result->{result}{ships_building}[0]{id};
            my $example = Lacuna->db->resultset('Ships')->find($ship_id);
            diag("Building more ships of type [$ship] id [$ship_id][$example]");

            for (1..$ships->{$ship}) {
                Lacuna->db->resultset('Ships')->create({
                    body_id         => $example->body_id,
                    shipyard_id     => $example->shipyard_id,
                    date_started    => $example->date_started,
                    date_available  => $example->date_available,
                    type            => $example->type,
                    task            => $example->task,
                    name            => $example->name,
                    speed           => $example->speed,
                    stealth         => $example->stealth,
                    combat          => $example->combat,
                    hold_size       => $example->hold_size,
                    payload         => $example->payload,
                    roundtrip       => $example->roundtrip,
                    direction       => $example->direction,
                    foreign_body_id => $example->foreign_body_id,
                    foreign_star_id => $example->foreign_star_id,
                    fleet_speed     => $example->fleet_speed,
                });
            }
        }
    }
    diag("Generating Spies");
    for (1..1000) {
        my $spy = $empire->add_to_spies({
            name                => 'Null',
            from_body_id        => $planet->id,
            on_body_id          => $planet->id,
            task                => 'Counter Espionage',
            started_assignment  => '2012-01-01 12:00:00',
            available_on        => '2012-01-01 12:00:00',
            offense             => 2600,
            defense             => 2600,
            date_created        => DateTime->now(),
            offense_mission_count   => 10 + int(rand(10)),
            defense_mission_count   => 10 + int(rand(10)),
            offense_mission_successes   => int(rand(3)),
            defense_mission_successes   => int(rand(3)),
            times_captured      => 0,
            times_turned        => 0,
            seeds_planted       => 0,
            spies_turned        => 0,
            spies_captured      => 0,
            spies_killed        => 0,
            things_destroyed    => int(rand(3)),
            things_stolen       => int(rand(5)),
            intel_xp            => 95 + int(rand(5)),
            mayhem_xp           => 95 + int(rand(5)),
            politics_xp         => 95 + int(rand(5)),
            theft_xp            => 95 + int(rand(5)),
            level               => 27 + int(rand(10)),
        });
        $spy->name("ICY ".$spy->id);
        $spy->update;
    }
}

1;
