use lib '../lib';
use Test::More tests => 90;
use 5.010;
use Lacuna;
use DateTime;
use TestHelper;

# Set up a planet that can be used for AI Attacks, both to and against

my $tester = TestHelper->new({empire_name => 'TLE Test Empire'});
my $empire = $tester->empire;
my $session = $empire->start_session({api_key => 'tester'});

my ($planet) = Lacuna->db->resultset('Map::Body::Planet')->search({name => 'Test-10'});

build_big_colony($tester, $planet);

sub build_big_colony {
    my ($tester, $planet) = @_;

    my $empire = $planet->empire;
    $planet->buildings->search({})->delete_all;
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
#        '' => [ { x => , y => , level => 30 }, ],
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

    # Add ships
    my ($shipyard) = $planet->buildings->search({ class => 'Lacuna::DB::Result::Building::Shipyard' });
    diag("Generating ships [".$session->id."][".$shipyard->id."]");
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
        # Create one ship as a 'template'
        my $result = $tester->post('shipyard', 'build_ship', [$session->id, $shipyard->id, $ship]);
        $tester->finish_ships( $shipyard->id );
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

    # Add Spies
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

