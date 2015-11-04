package Lacuna::AI::Jackpot;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::AI';

use Lacuna::Constants qw(ORE_TYPES);
use constant empire_id  => -4;

has viable_colonies => (
    is          => 'ro',
    lazy        => 1,
    default     => sub {
        return Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
            { empire_id => undef, zone => '0|0', orbit => { between => [1,7] }, size => { between => [30,65]}},
            );
    }
);

sub empire_defaults {
    return {
        name                    => 'Jackpot',
        status_message          => 'Target',
        description             => 'Free for All',
        species_name            => 'Meat Prizes',
        species_description     => 'Targets.',
        min_orbit               => 1,
        max_orbit               => 7,
        manufacturing_affinity  => 7, 
        deception_affinity      => 7,
        research_affinity       => 7,
        management_affinity     => 7,
        farming_affinity        => 7,
        mining_affinity         => 7,
        science_affinity        => 7,
        environmental_affinity  => 7,
        political_affinity      => 7,
        trade_affinity          => 7,
        growth_affinity         => 7,
        is_isolationist         => 0,
    };
}

sub colony_structures {
    return (
        ['Lacuna::DB::Result::Building::Waste::Sequestration', 20],
        ['Lacuna::DB::Result::Building::Intelligence', 15],
        ['Lacuna::DB::Result::Building::Security', 5],
        ['Lacuna::DB::Result::Building::Shipyard', 15],
        ['Lacuna::DB::Result::Building::Shipyard', 15],
        ['Lacuna::DB::Result::Building::Shipyard', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::Observatory',15],
        ['Lacuna::DB::Result::Building::Oversight',15],
        ['Lacuna::DB::Result::Building::Archaeology',10],
        ['Lacuna::DB::Result::Building::Trade', 15],
        ['Lacuna::DB::Result::Building::SAW',15],
        ['Lacuna::DB::Result::Building::SAW',15],
        ['Lacuna::DB::Result::Building::SAW',15],
        ['Lacuna::DB::Result::Building::SAW',15],
        ['Lacuna::DB::Result::Building::Permanent::Volcano',15],
        ['Lacuna::DB::Result::Building::Permanent::NaturalSpring',15],
        ['Lacuna::DB::Result::Building::Permanent::GratchsGauntlet',15],
        ['Lacuna::DB::Result::Building::Permanent::InterDimensionalRift',15],
        ['Lacuna::DB::Result::Building::Permanent::GeoThermalVent',15],
        ['Lacuna::DB::Result::Building::Permanent::KalavianRuins',15],
        ['Lacuna::DB::Result::Building::Permanent::MalcudField',15],
        ['Lacuna::DB::Result::Building::Permanent::AlgaePond',15],
        ['Lacuna::DB::Result::Building::Permanent::Ravine',15],
        ['Lacuna::DB::Result::Building::Water::Storage',15],
        ['Lacuna::DB::Result::Building::Ore::Storage',15],
        ['Lacuna::DB::Result::Building::Energy::Reserve',15],
        ['Lacuna::DB::Result::Building::Food::Reserve',15],
        ['Lacuna::DB::Result::Building::Food::Corn',15],
        ['Lacuna::DB::Result::Building::Food::Wheat',15],
        ['Lacuna::DB::Result::Building::Food::Dairy',15],
);
}

sub extra_glyph_buildings {
    return {
        quantity    => 0,
        min_level   => 1,
        max_level   => 1,
    }
}

sub spy_missions {
# Missions run by script
    return (
        'Appropriate Resources',
        'Sabotage Resources',
    );
}

sub ship_building_priorities {
    return (
        ['cargo_ship', 15],
        ['galleon', 5],
    );
}

sub run_hourly_colony_updates {
    my ($self, $colony) = @_;
    $self->demolish_bleeders($colony);
    $self->reject_badspy($colony);
    $self->set_defenders($colony);
    $self->pod_check($colony, 10);
    $self->reset_stuff($colony);
    $self->repair_buildings($colony);
    $self->train_spies($colony, 100);
    $self->build_ships($colony);
    $self->run_missions($colony);
}

sub reset_stuff {
    my ($self, $colony) = @_;

    print "Resetting Happiness\n";
    if ($colony->happiness < 1_000_000_000_000) {
        $colony->happiness(1_000_000_000_000);
        $colony->update;
    }

    print "Resetting Buildings\n";
    my %structures = map { $_->[0] => $_->[1] } $self->colony_structures;

    foreach my $building (@{$colony->building_cache}) {
        if ($structures{$building->class} and $structures{$building->class} > $building->level ) {
            print "Resetting ".$building->class." to ".$structures{$building->class}." from ".$building->level.".\n";
            $building->level($structures{$building->class});
            $building->update;
        }
    }
    print "Resetting Glyphs\n";
    my $glyphs = $colony->glyph;
    my %ghash = map {$_ => 0 } (ORE_TYPES);
    while (my $glyph = $glyphs->next) {
        $ghash{$glyph->type} += $glyph->quantity;
    }
    for my $type (ORE_TYPES) {
        if ($ghash{$type} < 250) {
            $colony->add_glyph($type, 250 - $ghash{$type});
        }
    }
    print "Resetting Plans\n";
    my $plans =  $colony->plan_cache;
    my %phash;
    for my $plan (@{$plans}) {
        my $key = join(":",$plan->class,$plan->level,$plan->extra_build_level);
        $phash{$key} = $plan->quantity;
    }
    print "Checking Plans\n";
    my $qplans = plan_list();
    for my $plan (@{$qplans}) {
        my $key = join(":",$plan->{class},$plan->{level},$plan->{extra});
        if ( (!defined $phash{$key} or $phash{$key} < $plan->{quantity}) and $plan->{chance} > rand(100)) {
            printf "Adding %d %s\n", $plan->{quantity} - $phash{$key}, $key;
            $colony->add_plan($plan->{class}, $plan->{level}, $plan->{extra}, $plan->{quantity} - $phash{$key});
        }
    }
}

sub reject_badspy {
    my ($self, $colony) = @_;

    print "Bouncing Spies that are too advanced\n";
    my %empires;
    my $spies = Lacuna->db->resultset('Spies')->search({
                    'me.on_body_id' => $colony->id,
                    'me.empire_id'  => {'!=' => $colony->empire_id },
                    'me.task'       => { 'not in' => ['Killed In Action',
                                                      'Travelling',
                                                      'Captured',
                                                      'Prisoner Transport'] },
                    'empire.university_level' => { '>' => 15 },
                },{
                    join                      => 'empire',
    });
    while (my $spy = $spies->next) {
        printf "    Spy ID: %d from %s sent home\n",$spy->id, $spy->empire->name;
        $spy->task("Idle");
        my $result = eval { $spy->assign("Bugout") };
        unless ($empires{$spy->empire->id} ) {
            $empires{$spy->empire->id} = 1;
            $spy->empire->send_predefined_message(
                from        => $colony->empire,
                tags        => ['Spies','Alert'],
                filename    => 'jackpot_reject.txt',
            )
        }
    }
}

sub plan_list {
return ([
  { "class" => "Lacuna::DB::Result::Building::Permanent::AlgaePond", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::AlgaePond", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::AmalgusMeadow", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::AmalgusMeadow", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach1", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach1", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach1", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach1", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach1", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach1", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach1", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach1", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach2", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach2", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach2", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach2", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach2", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach2", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach2", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach2", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach3", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach3", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach3", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach3", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach3", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach3", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach3", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach3", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach4", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach4", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach4", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach4", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach4", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach4", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach4", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach4", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach5", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach5", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach5", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach5", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach5", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach5", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach5", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach5", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach6", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach6", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach6", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach6", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach6", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach6", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach6", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach6", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach7", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach7", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach7", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach7", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach7", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach7", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach7", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach7", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach8", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach8", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach8", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach8", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach8", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach8", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach8", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach8", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach9", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach9", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach9", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach9", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach9", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach9", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach9", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach9", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach10", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach10", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach10", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach10", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach10", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach10", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach10", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach10", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach11", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach11", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach11", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach11", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach11", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach11", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach11", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach11", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach12", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach12", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach12", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach12", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach12", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach12", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach12", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach12", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach13", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach13", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach13", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach13", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach13", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach13", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach13", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Beach13", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::BeeldebanNest", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::BeeldebanNest", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::CitadelOfKnope", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::CitadelOfKnope", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::CrashedShipSite", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::CrashedShipSite", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Crater", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Crater", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Crater", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Crater", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Crater", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Crater", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Crater", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Crater", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::DentonBrambles", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::DentonBrambles", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::GasGiantPlatform", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::GeoThermalVent", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::GeoThermalVent", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::GratchsGauntlet", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::GratchsGauntlet", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Grove", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Grove", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Grove", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Grove", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Grove", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Grove", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Grove", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Grove", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk", "level" => "1", "extra" => "0", "quantity" => "50", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::InterDimensionalRift", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::InterDimensionalRift", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::KalavianRuins", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::KalavianRuins", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lagoon", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lagoon", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lagoon", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lagoon", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lagoon", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lagoon", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lagoon", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lagoon", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lake", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lake", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lake", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lake", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lake", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lake", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lake", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Lake", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::LapisForest", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::LapisForest", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::LibraryOfJith", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::LibraryOfJith", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::MalcudField", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::MalcudField", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::NaturalSpring", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::NaturalSpring", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::OracleOfAnid", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::OracleOfAnid", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::PantheonOfHagness", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::PantheonOfHagness", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Ravine", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Ravine", "level" => "1", "extra" => "4", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::RockyOutcrop", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::RockyOutcrop", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::RockyOutcrop", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::RockyOutcrop", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::RockyOutcrop", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::RockyOutcrop", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::RockyOutcrop", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::RockyOutcrop", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Sand", "level" => "1", "extra" => "0", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Sand", "level" => "1", "extra" => "1", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Sand", "level" => "1", "extra" => "2", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Sand", "level" => "1", "extra" => "3", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Sand", "level" => "1", "extra" => "4", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Sand", "level" => "1", "extra" => "5", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Sand", "level" => "1", "extra" => "6", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Sand", "level" => "1", "extra" => "7", "quantity" => "250", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::TempleOfTheDrajilites", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::TempleOfTheDrajilites", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::TerraformingPlatform", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Volcano", "level" => "1", "extra" => "0", "quantity" => "25", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Permanent::Volcano", "level" => "1", "extra" => "4", "quantity" => "5", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::SAW", "level" => "1", "extra" => "0", "quantity" => "10", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::SAW", "level" => "1", "extra" => "9", "quantity" => "1", "chance" => "10" },
  { "class" => "Lacuna::DB::Result::Building::DistributionCenter", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Bread", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Burger", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Cheese", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Chip", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Cider", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::CornMeal", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Pancake", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Pie", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Shake", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Soup", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Syrup", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Algae", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Apple", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Beeldeban", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Bean", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Corn", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Dairy", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Lapis", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Malcud", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Potato", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Root", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::Food::Wheat", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "100" },
  { "class" => "Lacuna::DB::Result::Building::LCOTa", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "5" },
  { "class" => "Lacuna::DB::Result::Building::LCOTb", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "5" },
  { "class" => "Lacuna::DB::Result::Building::LCOTc", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "5" },
  { "class" => "Lacuna::DB::Result::Building::LCOTd", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "5" },
  { "class" => "Lacuna::DB::Result::Building::LCOTe", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "5" },
  { "class" => "Lacuna::DB::Result::Building::LCOTf", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "5" },
  { "class" => "Lacuna::DB::Result::Building::LCOTg", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "5" },
  { "class" => "Lacuna::DB::Result::Building::LCOTh", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "5" },
  { "class" => "Lacuna::DB::Result::Building::LCOTi", "level" => "1", "extra" => "0", "quantity" => "1", "chance" => "5" }
]);
}

no Moose;
__PACKAGE__->meta->make_immutable;
