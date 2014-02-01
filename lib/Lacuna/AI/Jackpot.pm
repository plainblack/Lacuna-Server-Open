package Lacuna::AI::Jackpot;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::AI';

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
        ['Lacuna::DB::Result::Building::Waste::Sequestration', 16],
        ['Lacuna::DB::Result::Building::Intelligence', 10],
        ['Lacuna::DB::Result::Building::Security', 15],
        ['Lacuna::DB::Result::Building::Shipyard', 10],
        ['Lacuna::DB::Result::Building::SpacePort', 20],
        ['Lacuna::DB::Result::Building::SpacePort', 20],
        ['Lacuna::DB::Result::Building::SpacePort', 20],
        ['Lacuna::DB::Result::Building::SpacePort', 20],
        ['Lacuna::DB::Result::Building::SpacePort', 20],
        ['Lacuna::DB::Result::Building::Observatory',15],
        ['Lacuna::DB::Result::Building::Archaeology',10],
        ['Lacuna::DB::Result::Building::Trade', 15],
        ['Lacuna::DB::Result::Building::SAW',20],
        ['Lacuna::DB::Result::Building::SAW',20],
        ['Lacuna::DB::Result::Building::SAW',20],
        ['Lacuna::DB::Result::Building::SAW',20],
        ['Lacuna::DB::Result::Building::SAW',20],
        ['Lacuna::DB::Result::Building::Permanent::Volcano',15],
        ['Lacuna::DB::Result::Building::Permanent::NaturalSpring',15],
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
    $self->set_defenders($colony);
    $self->pod_check($colony, 10);
    $self->reset_stuff($colony);
    $self->train_spies($colony);
    $self->build_ships($colony);
    $self->run_missions($colony);
}

sub reset_stuff {
    my ($self, $colony) = @_;

    my %structures = map { $_[0] => $_[1] } $self->colony_structures;

    foreach my $building (@{$colony->building_cache}) {
        if ($structures{$building->class} and $structures{$building->class} > $building->level ) {
            $building->level = $structures{$building->class};
            $building->update;
        }
    }
#place plans?
}

no Moose;
__PACKAGE__->meta->make_immutable;
