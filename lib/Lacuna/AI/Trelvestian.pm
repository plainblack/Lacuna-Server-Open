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
            { empire_id => undef, orbit => { between => [5,6] }, size => { between => [50,75]}},
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
        ['Lacuna::DB::Result::Building::Permanent::EssentiaVein',29],
        ['Lacuna::DB::Result::Building::Permanent::GeoThermalVent',25],
        ['Lacuna::DB::Result::Building::Permanent::GratchsGauntlet',16],
        ['Lacuna::DB::Result::Building::Permanent::NaturalSpring',25],
        ['Lacuna::DB::Result::Building::Permanent::Volcano',25],
        ['Lacuna::DB::Result::Building::Permanent::AlgaePond',25],
        ['Lacuna::DB::Result::Building::Permanent::BeeldebanNest',25],
        ['Lacuna::DB::Result::Building::Permanent::MalcudField',25],
        ['Lacuna::DB::Result::Building::Permanent::GreatBallOfJunk',11],
        ['Lacuna::DB::Result::Building::Permanent::JunkHengeSculpture',12],
        ['Lacuna::DB::Result::Building::Permanent::MetalJunkArches',9],
        ['Lacuna::DB::Result::Building::Permanent::KalavianRuins',18],
        ['Lacuna::DB::Result::Building::Permanent::OracleOfAnid',10],
        ['Lacuna::DB::Result::Building::Intelligence', 25],
        ['Lacuna::DB::Result::Building::Security', 30],
        ['Lacuna::DB::Result::Building::MunitionsLab', 25],
        ['Lacuna::DB::Result::Building::Shipyard',22],
        ['Lacuna::DB::Result::Building::Shipyard',22],
        ['Lacuna::DB::Result::Building::Shipyard',22],
        ['Lacuna::DB::Result::Building::SpacePort', 25],
        ['Lacuna::DB::Result::Building::SpacePort', 25],
        ['Lacuna::DB::Result::Building::SpacePort', 25],
        ['Lacuna::DB::Result::Building::SpacePort', 25],
        ['Lacuna::DB::Result::Building::SpacePort', 25],
        ['Lacuna::DB::Result::Building::SpacePort', 25],
        ['Lacuna::DB::Result::Building::SpacePort', 25],
        ['Lacuna::DB::Result::Building::SpacePort', 25],
        ['Lacuna::DB::Result::Building::SpacePort', 25],
        ['Lacuna::DB::Result::Building::SpacePort', 25],
        ['Lacuna::DB::Result::Building::PilotTraining',25],
        ['Lacuna::DB::Result::Building::Energy::Reserve', 30],
        ['Lacuna::DB::Result::Building::Food::Reserve', 30],
        ['Lacuna::DB::Result::Building::Ore::Storage', 30],
        ['Lacuna::DB::Result::Building::Water::Storage', 30],
        ['Lacuna::DB::Result::Building::Waste::Sequestration', 30],
        ['Lacuna::DB::Result::Building::Waste::Exchanger', 20],
        ['Lacuna::DB::Result::Building::Waste::Exchanger', 20],
        ['Lacuna::DB::Result::Building::Food::Beeldeban',20],
        ['Lacuna::DB::Result::Building::Food::Root',20],
        ['Lacuna::DB::Result::Building::Food::Beeldeban',20],
        ['Lacuna::DB::Result::Building::Food::Root',20],
        ['Lacuna::DB::Result::Building::Ore::Refinery',20],
        ['Lacuna::DB::Result::Building::Ore::Mine',20],
        ['Lacuna::DB::Result::Building::Ore::Mine',20],
        ['Lacuna::DB::Result::Building::Ore::Mine',20],
        ['Lacuna::DB::Result::Building::Ore::Mine',20],
        ['Lacuna::DB::Result::Building::Energy::Singularity',20],
        ['Lacuna::DB::Result::Building::Energy::Singularity',20],
        ['Lacuna::DB::Result::Building::Energy::Fusion',20],
        ['Lacuna::DB::Result::Building::Energy::Fusion',20],
        ['Lacuna::DB::Result::Building::Water::Production',20],
        ['Lacuna::DB::Result::Building::Water::Production',20],
        ['Lacuna::DB::Result::Building::Water::AtmosphericEvaporator',20],
        ['Lacuna::DB::Result::Building::Water::AtmosphericEvaporator',20],
        ['Lacuna::DB::Result::Building::SAW',25],
        ['Lacuna::DB::Result::Building::SAW',25],
        ['Lacuna::DB::Result::Building::SAW',25],
        ['Lacuna::DB::Result::Building::SAW',25],
        ['Lacuna::DB::Result::Building::SAW',25],
        ['Lacuna::DB::Result::Building::SAW',25],
        ['Lacuna::DB::Result::Building::SAW',25],
        ['Lacuna::DB::Result::Building::SAW',25],
        ['Lacuna::DB::Result::Building::Observatory', 10],
        ['Lacuna::DB::Result::Building::Permanent::TerraformingPlatform',10],
        ['Lacuna::DB::Result::Building::Permanent::TerraformingPlatform',10],
        ['Lacuna::DB::Result::Building::Permanent::TerraformingPlatform',10],
        ['Lacuna::DB::Result::Building::Permanent::TerraformingPlatform',10],
    );
}

sub extra_glyph_buildings {
    return {
        quantity    => 0,
        min_level   => 1,
        max_level   => 5,
    }
}

sub spy_missions {
    return (
        'Appropriate Resources',
        'Sabotage Infrastructure',
    );
}

sub ship_building_priorities {
    return (
        ['drone', 50],
        ['fighter', 50],
        ['probe', 5],
        ['sweeper', 50],
        ['snark',  5],
        ['snark2',15],
        ['snark3',50],
    );
}

sub run_hourly_colony_updates {
    my ($self, $colony) = @_;
    $self->demolish_bleeders($colony);
    $self->kill_prisoners($colony, 96);
    $self->set_defenders($colony);
    $self->pod_check($colony, 25);
    $self->repair_buildings($colony);
    $self->train_spies($colony, 100, 1);
    $self->build_ships($colony);
    $self->run_missions($colony);
}

no Moose;
__PACKAGE__->meta->make_immutable;
