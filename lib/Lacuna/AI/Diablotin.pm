package Lacuna::AI::Diablotin;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::AI';

use constant empire_id  => -7;

has viable_colonies => (
    is          => 'ro',
    lazy        => 1,
    default     => sub {
        return Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
            { empire_id => undef, orbit => 7, size => { between => [45,49]}},
            );
    }
);

sub empire_defaults {
    return {
        name                    => 'Diablotin',
        status_message          => 'Vous tes le bouffon!',
        description             => 'La plaisanterie est sur toi.',
        species_name            => 'Diablotin',
        species_description     => 'Nous aimons nous amuser.',
        min_orbit               => 7,
        max_orbit               => 7,
        manufacturing_affinity  => 7, 
        deception_affinity      => 7,
        research_affinity       => 1,
        management_affinity     => 1,
        farming_affinity        => 6,
        mining_affinity         => 1,
        science_affinity        => 7,
        environmental_affinity  => 6,
        political_affinity      => 6,
        trade_affinity          => 1,
        growth_affinity         => 1,
        is_isolationist         => 0,
    };
}

sub colony_structures {
    return (
        ['Lacuna::DB::Result::Building::Waste::Sequestration', 15],
        ['Lacuna::DB::Result::Building::Waste::Sequestration', 15],
        ['Lacuna::DB::Result::Building::Intelligence', 15],
        ['Lacuna::DB::Result::Building::Security', 15],
        ['Lacuna::DB::Result::Building::LuxuryHousing',10],
        ['Lacuna::DB::Result::Building::CloakingLab', 15],
        ['Lacuna::DB::Result::Building::MunitionsLab', 3],
        ['Lacuna::DB::Result::Building::Shipyard', 4],
        ['Lacuna::DB::Result::Building::Shipyard', 4],
        ['Lacuna::DB::Result::Building::Shipyard', 4],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::Observatory',15],
        ['Lacuna::DB::Result::Building::Food::Syrup',15],
        ['Lacuna::DB::Result::Building::Food::Burger',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Ore::Refinery',13],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Energy::Singularity',15],
        ['Lacuna::DB::Result::Building::Energy::Singularity',12],
        ['Lacuna::DB::Result::Building::Water::Reclamation',15],
        ['Lacuna::DB::Result::Building::Water::Reclamation',15],
        ['Lacuna::DB::Result::Building::Water::Reclamation',15],
        ['Lacuna::DB::Result::Building::Water::AtmosphericEvaporator',14],
        ['Lacuna::DB::Result::Building::Archaeology',10],
        ['Lacuna::DB::Result::Building::SAW',10],
        ['Lacuna::DB::Result::Building::SAW',10],
        ['Lacuna::DB::Result::Building::SAW',10],
        ['Lacuna::DB::Result::Building::SAW',10],
        ['Lacuna::DB::Result::Building::SAW',10],
        ['Lacuna::DB::Result::Building::SAW',10],
    );
}

sub extra_glyph_buildings {
    return {
        quantity    => 1,
        min_level   => 1,
        max_level   => 30,
    }
}

sub spy_missions {
    return (
        'Appropriate Resources',
        'Sabotage Resources',
    );
}

sub ship_building_priorities {
    return (
        ['drone', 14],
        ['probe', 4],
        ['thud', 18],
        ['placebo2', 18],
        ['placebo3', 18],
        ['placebo', 18],
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
