package Lacuna::AI::Trelvestian;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::AI';

use constant empire_id  => -3;

has viable_colonies => (
    is          => 'ro',
    lazy        => 1,
    default     => sub {
        return Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
            { empire_id => undef, orbit => { between => [5,6] }, size => { between => [50,60]}},
            );
    }
);

sub empire_defaults {
    return {
        name                    => 'Trelvestian Sveitarfélagi',
        status_message          => 'Grafa Essentia',
        description             => 'Þú koma sjúkdómnum. Þú koma dauða. Láttu okkur vera.',
        species_name            => 'Trelvestivð',
        species_description     => 'Við viljum vera í friði.',
        min_orbit               => 5,
        max_orbit               => 6,
        manufacturing_affinity  => 6, 
        deception_affinity      => 4,
        research_affinity       => 1,
        management_affinity     => 1,
        farming_affinity        => 7,
        mining_affinity         => 7,
        science_affinity        => 7,
        environmental_affinity  => 7,
        political_affinity      => 1,
        trade_affinity          => 1,
        growth_affinity         => 1,
        is_isolationist         => 0,
    };
}

sub colony_structures {
    return (
        ['Lacuna::DB::Result::Building::Permanent::EssentiaVein',1],
        ['Lacuna::DB::Result::Building::Permanent::GeoThermalVent',20],
        ['Lacuna::DB::Result::Building::Permanent::NaturalSpring',20],
        ['Lacuna::DB::Result::Building::Permanent::Volcano',20],
        ['Lacuna::DB::Result::Building::Permanent::AlgaePond',16],
        ['Lacuna::DB::Result::Building::Permanent::BeeldebanNest',16],
        ['Lacuna::DB::Result::Building::Permanent::MalcudField',16],
        ['Lacuna::DB::Result::Building::Permanent::GreatBallOfJunk',15],
        ['Lacuna::DB::Result::Building::Permanent::JunkHengeSculpture',15],
        ['Lacuna::DB::Result::Building::Permanent::MetalJunkArches',15],
        ['Lacuna::DB::Result::Building::Permanent::KalavianRuins',15],
        ['Lacuna::DB::Result::Building::Intelligence', 25],
        ['Lacuna::DB::Result::Building::Security', 25],
        ['Lacuna::DB::Result::Building::MunitionsLab', 25],
        ['Lacuna::DB::Result::Building::Shipyard', 4],
        ['Lacuna::DB::Result::Building::Shipyard', 4],
        ['Lacuna::DB::Result::Building::Shipyard', 4],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::Observatory',15],
        ['Lacuna::DB::Result::Building::PilotTraining',1],
        ['Lacuna::DB::Result::Building::Energy::Reserve', 20],
        ['Lacuna::DB::Result::Building::Food::Reserve', 20],
        ['Lacuna::DB::Result::Building::Ore::Storage', 20],
        ['Lacuna::DB::Result::Building::Water::Storage', 20],
        ['Lacuna::DB::Result::Building::Food::Beeldeban',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Algae',15],
        ['Lacuna::DB::Result::Building::Food::Root',15],
        ['Lacuna::DB::Result::Building::Food::Beeldeban',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Algae',15],
        ['Lacuna::DB::Result::Building::Food::Root',15],
        ['Lacuna::DB::Result::Building::Ore::Refinery',15],
        ['Lacuna::DB::Result::Building::Ore::Mine',15],
        ['Lacuna::DB::Result::Building::Ore::Mine',15],
        ['Lacuna::DB::Result::Building::Ore::Mine',15],
        ['Lacuna::DB::Result::Building::Ore::Mine',15],
        ['Lacuna::DB::Result::Building::Ore::Mine',15],
        ['Lacuna::DB::Result::Building::Ore::Mine',15],
        ['Lacuna::DB::Result::Building::Ore::Mine',15],
        ['Lacuna::DB::Result::Building::Ore::Mine',15],
        ['Lacuna::DB::Result::Building::Ore::Mine',15],
        ['Lacuna::DB::Result::Building::Energy::Singularity',15],
        ['Lacuna::DB::Result::Building::Energy::Singularity',15],
        ['Lacuna::DB::Result::Building::Energy::Fusion',15],
        ['Lacuna::DB::Result::Building::Energy::Fusion',15],
        ['Lacuna::DB::Result::Building::Energy::Fusion',15],
        ['Lacuna::DB::Result::Building::Water::Production',15],
        ['Lacuna::DB::Result::Building::Water::Production',15],
        ['Lacuna::DB::Result::Building::Water::Production',15],
        ['Lacuna::DB::Result::Building::Water::AtmosphericEvaporator',15],
        ['Lacuna::DB::Result::Building::Water::AtmosphericEvaporator',15],
        ['Lacuna::DB::Result::Building::SAW',10],
        ['Lacuna::DB::Result::Building::SAW',10],
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
        max_level   => 5,
    }
}

sub spy_missions {
    return (
        'Appropriate Resources',
    );
}

sub ship_building_priorities {
    return (
        ['drone', 40],
        ['fighter', 20],
        ['sweeper', 20],
        ['probe', 1],
        ['bleeder', 10],
        ['security_ministry_seeker', 3],
        ['space_port_seeker', 3],
        ['snark', 12],
        ['snark2', 5],
        ['snark3', 3],
        ['thud', 5],
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
