package Lacuna::AI::Saben;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::AI';

use constant empire_id  => -1;

has viable_colonies => (
    is          => 'ro',
    lazy        => 1,
    default     => sub {
        return Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
            { empire_id => undef, orbit => 7, size => { between => [30,35]}},
            );
    }
);

sub empire_defaults {
    return {
        name                    => 'Sābēn Demesne',
        status_message          => 'Waging war!',
        description             => 'We see you looking at our description. Know this, we have looked at your description as well, and found it lacking. You do not deserve to share our Demesne.',
        species_name            => 'Sābēn',
        species_description     => 'A solitary people who wish to be left alone.',
        min_orbit               => 1,
        max_orbit               => 7,
        manufacturing_affinity  => 4, 
        deception_affinity      => 7, 
        research_affinity       => 1, 
        management_affinity     => 7, 
        farming_affinity        => 1, 
        mining_affinity         => 1, 
        science_affinity        => 7, 
        environmental_affinity  => 1, 
        political_affinity      => 1, 
        trade_affinity          => 7, 
        growth_affinity         => 1, 
        is_isolationist         => 0,
    };
}

sub colony_structures {
    return (
    ['Lacuna::DB::Result::Building::Waste::Sequestration',10],
    ['Lacuna::DB::Result::Building::Permanent::Ravine',10],
    ['Lacuna::DB::Result::Building::Espionage', 20],
    ['Lacuna::DB::Result::Building::Intelligence', 25],
    ['Lacuna::DB::Result::Building::Security', 20],
    ['Lacuna::DB::Result::Building::Permanent::CitadelOfKnope',10],
    ['Lacuna::DB::Result::Building::Observatory', 15],
    ['Lacuna::DB::Result::Building::Shipyard', 4],
    ['Lacuna::DB::Result::Building::Shipyard', 4],
    ['Lacuna::DB::Result::Building::Shipyard', 4],
    ['Lacuna::DB::Result::Building::SpacePort',20],
    ['Lacuna::DB::Result::Building::SpacePort',20],
    ['Lacuna::DB::Result::Building::SpacePort',20],
    ['Lacuna::DB::Result::Building::MunitionsLab', 20],
    ['Lacuna::DB::Result::Building::Trade', 20],
    ['Lacuna::DB::Result::Building::Permanent::CrashedShipSite',15],
    ['Lacuna::DB::Result::Building::Permanent::Volcano',25],
    ['Lacuna::DB::Result::Building::Permanent::NaturalSpring',25],
    ['Lacuna::DB::Result::Building::Permanent::InterDimensionalRift',25],
    ['Lacuna::DB::Result::Building::Permanent::GeoThermalVent',25],
    ['Lacuna::DB::Result::Building::Permanent::KalavianRuins',5],
    ['Lacuna::DB::Result::Building::Permanent::MalcudField',25],
    ['Lacuna::DB::Result::Building::Permanent::AlgaePond',25],
    ['Lacuna::DB::Result::Building::Food::Syrup',10],
    ['Lacuna::DB::Result::Building::Food::Burger',10],
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
    return (
        'Incite Rebellion',
        'Incite Mutany',
        'Appropriate Resources',
    );
}

sub ship_building_priorities {
    return (
        ['drone', 10],
        ['sweeper', 30],
        ['probe', 1],
        ['scow', 15],
        ['bleeder', 20],
        ['spy_pod', 5],
        ['security_ministry_seeker', 3],
        ['space_port_seeker', 3],
        ['snark', 15],
        ['snark2', 5],
        ['thud', 20],
        ['observatory_seeker', 3],
    );
}

sub run_hourly_colony_updates {
    my ($self, $colony) = @_;
    $self->set_defenders($colony);
    $self->repair_buildings($colony);
    $self->train_spies($colony);
    $self->build_ships($colony);
    $self->run_missions($colony);
}

no Moose;
__PACKAGE__->meta->make_immutable;
