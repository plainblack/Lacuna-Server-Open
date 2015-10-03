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
            { empire_id => undef, orbit => 7, size => { between => [45,70]}},
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
        ['Lacuna::DB::Result::Building::Archaeology',10],
        ['Lacuna::DB::Result::Building::CloakingLab', 15],
        ['Lacuna::DB::Result::Building::Energy::Hydrocarbon',15],
        ['Lacuna::DB::Result::Building::Energy::Singularity',15],
        ['Lacuna::DB::Result::Building::Energy::Reserve', 15],
        ['Lacuna::DB::Result::Building::Energy::Waste',15],
        ['Lacuna::DB::Result::Building::Food::Algae',15],
        ['Lacuna::DB::Result::Building::Food::Algae',15],
        ['Lacuna::DB::Result::Building::Food::Algae',15],
        ['Lacuna::DB::Result::Building::Food::Burger',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Reserve', 15],
        ['Lacuna::DB::Result::Building::Food::Syrup',15],
        ['Lacuna::DB::Result::Building::Intelligence', 10],
        ['Lacuna::DB::Result::Building::LuxuryHousing',15],
        ['Lacuna::DB::Result::Building::MunitionsLab', 12],
        ['Lacuna::DB::Result::Building::Observatory',10],
        ['Lacuna::DB::Result::Building::Ore::Mine',15],
        ['Lacuna::DB::Result::Building::Ore::Mine',15],
        ['Lacuna::DB::Result::Building::Ore::Refinery',15],
        ['Lacuna::DB::Result::Building::Ore::Storage',15],
        ['Lacuna::DB::Result::Building::SAW',10],
        ['Lacuna::DB::Result::Building::SAW',10],
        ['Lacuna::DB::Result::Building::SAW',10],
        ['Lacuna::DB::Result::Building::SAW',10],
        ['Lacuna::DB::Result::Building::SAW',10],
        ['Lacuna::DB::Result::Building::SAW',10],
        ['Lacuna::DB::Result::Building::Security', 15],
        ['Lacuna::DB::Result::Building::Shipyard', 8],
        ['Lacuna::DB::Result::Building::Shipyard', 8],
        ['Lacuna::DB::Result::Building::Shipyard', 8],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Sequestration', 20],
        ['Lacuna::DB::Result::Building::Waste::Treatment',15],
        ['Lacuna::DB::Result::Building::Waste::Treatment',15],
        ['Lacuna::DB::Result::Building::Water::AtmosphericEvaporator',15],
        ['Lacuna::DB::Result::Building::Water::Reclamation',15],
        ['Lacuna::DB::Result::Building::Water::Reclamation',15],
        ['Lacuna::DB::Result::Building::Water::Reclamation',15],
        ['Lacuna::DB::Result::Building::Water::Storage',15],
    );
}

sub extra_glyph_buildings {
    my $return = {
        quantity    => 1,
        min_level   => 10,
        max_level   => 30,
    };
    $return->{findable} = [
        "Lacuna::DB::Result::Building::Permanent::AmalgusMeadow",
        "Lacuna::DB::Result::Building::Permanent::BeeldebanNest",
        "Lacuna::DB::Result::Building::Permanent::DentonBrambles",
        "Lacuna::DB::Result::Building::Permanent::GeoThermalVent",
        "Lacuna::DB::Result::Building::Permanent::GratchsGauntlet",
        "Lacuna::DB::Result::Building::Permanent::GreatBallOfJunk",
        "Lacuna::DB::Result::Building::Permanent::InterDimensionalRift",
        "Lacuna::DB::Result::Building::Permanent::NaturalSpring",
        "Lacuna::DB::Result::Building::Permanent::Volcano",
        "Lacuna::DB::Result::Building::Permanent::AlgaePond",
        "Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator",
        "Lacuna::DB::Result::Building::Permanent::CitadelOfKnope",
        "Lacuna::DB::Result::Building::Permanent::CrashedShipSite",
        "Lacuna::DB::Result::Building::Permanent::KalavianRuins",
        "Lacuna::DB::Result::Building::Permanent::LapisForest",
        "Lacuna::DB::Result::Building::Permanent::LibraryOfJith",
        "Lacuna::DB::Result::Building::Permanent::MalcudField",
        "Lacuna::DB::Result::Building::Permanent::OracleOfAnid",
        "Lacuna::DB::Result::Building::Permanent::PantheonOfHagness",
        "Lacuna::DB::Result::Building::Permanent::Ravine",
        "Lacuna::DB::Result::Building::Permanent::TempleOfTheDrajilites",
    ];
    return $return;
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
        ['bleeder', 18],
    );
}

sub run_hourly_colony_updates {
    my ($self, $colony) = @_;
    $self->demolish_bleeders($colony);
    $self->kill_prisoners($colony, 24);
    $self->set_defenders($colony);
    $self->pod_check($colony, 15);
    $self->repair_buildings($colony);
    $self->train_spies($colony, 50);
    $self->build_ships($colony);
    $self->run_missions($colony);
}

no Moose;
__PACKAGE__->meta->make_immutable;
