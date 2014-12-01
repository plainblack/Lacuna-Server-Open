package Lacuna::AI::Saben;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::AI';
use 5.010;
use Lacuna::Util qw(randint format_date);

use constant empire_id  => -1;

has viable_colonies => (
    is          => 'ro',
    lazy        => 1,
    default     => sub {
        return Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
            { empire_id => undef, orbit => 7, size => { between => [30,70]}},
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
    ['Lacuna::DB::Result::Building::Waste::Sequestration',30],
    ['Lacuna::DB::Result::Building::Development', 5],
    ['Lacuna::DB::Result::Building::Intelligence', 30],
    ['Lacuna::DB::Result::Building::Security', 30],
    ['Lacuna::DB::Result::Building::Espionage', 30],
    ['Lacuna::DB::Result::Building::Permanent::CitadelOfKnope',30],
    ['Lacuna::DB::Result::Building::Shipyard',30],
    ['Lacuna::DB::Result::Building::Shipyard',30],
    ['Lacuna::DB::Result::Building::Shipyard',30],
    ['Lacuna::DB::Result::Building::Shipyard',30],
    ['Lacuna::DB::Result::Building::Shipyard',30],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SpacePort',25],
    ['Lacuna::DB::Result::Building::SAW',25],
    ['Lacuna::DB::Result::Building::SAW',25],
    ['Lacuna::DB::Result::Building::SAW',25],
    ['Lacuna::DB::Result::Building::SAW',25],
    ['Lacuna::DB::Result::Building::SAW',25],
    ['Lacuna::DB::Result::Building::SAW',25],
    ['Lacuna::DB::Result::Building::SAW',25],
    ['Lacuna::DB::Result::Building::SAW',25],
    ['Lacuna::DB::Result::Building::MunitionsLab', 25],
    ['Lacuna::DB::Result::Building::Propulsion', 25],
    ['Lacuna::DB::Result::Building::Trade', 20],
    ['Lacuna::DB::Result::Building::Observatory', 10],
    ['Lacuna::DB::Result::Building::Permanent::CrashedShipSite',25],
    ['Lacuna::DB::Result::Building::Permanent::Volcano',30],
    ['Lacuna::DB::Result::Building::Permanent::NaturalSpring',30],
    ['Lacuna::DB::Result::Building::Permanent::InterDimensionalRift',30],
    ['Lacuna::DB::Result::Building::Permanent::GratchsGauntlet',20],
    ['Lacuna::DB::Result::Building::Permanent::GeoThermalVent',30],
    ['Lacuna::DB::Result::Building::Permanent::KalavianRuins',25],
    ['Lacuna::DB::Result::Building::Permanent::MalcudField',30],
    ['Lacuna::DB::Result::Building::Permanent::AlgaePond',30],
    ['Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator',30],
    ['Lacuna::DB::Result::Building::Food::Syrup',15],
    ['Lacuna::DB::Result::Building::Food::Burger',15],
    ['Lacuna::DB::Result::Building::Permanent::TerraformingPlatform',10],
    ['Lacuna::DB::Result::Building::Permanent::TerraformingPlatform',10],
    ['Lacuna::DB::Result::Building::Permanent::TerraformingPlatform',10],
    ['Lacuna::DB::Result::Building::Permanent::TerraformingPlatform',10],
    ['Lacuna::DB::Result::Building::Permanent::OracleOfAnid',15],
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
        'Incite Mutiny',
    );
}

sub ship_building_priorities {
    return (
        ['drone', 100],
        ['scanner', 10],
        ['sweeper', 50],
        ['probe', 5],
        ['scow', 50],
        ['bleeder', 25],
        ['snark', 50],
        ['snark2', 50],
        ['snark3', 50],
    );
}

sub run_hourly_colony_updates {
    my ($self, $colony) = @_;
    $self->demolish_bleeders($colony);
    $self->kill_prisoners($colony, 24);
    $self->set_defenders($colony);
    $self->pod_check($colony, 25);
    $self->repair_buildings($colony);
    $self->train_spies($colony,50, 1);
    $self->build_ships($colony);
    $self->run_missions($colony);
}

sub destroy_world {
    my ($self, $colony) = @_;
    if ($colony->is_bhg_neutralized) {
        say sprintf("BHG of %s is neutralized by a space station.",$colony->name);
        return;
    }
    my $enemies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')
                         ->search({on_body_id => $colony->id,
                                   task => 'Sabotage BHG',
                                   empire_id => { '!=' => $self->empire_id }})->count;
    if ($enemies) {
        say "Annoying non-saben on planet trying to Sabotage our BHG";
        return;
    }
    say "Looking for world to destroy...";
    my $targets = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({
            zone        => $colony->zone,
            size        => { between => [46, 75] },
            empire_id   => undef,
        },
        { rows => 20}
    );
    my $blownup = 0;
    while (my $target = $targets->next) {
        next if $target->is_bhg_neutralized;
        say "Found ".$target->name;
        my @to_demolish = @{$target->building_cache};
        $target->delete_buildings(\@to_demolish);
        $target->update({
            class                       => 'Lacuna::DB::Result::Map::Body::Asteroid::A'.randint(1,Lacuna::DB::Result::Map::Body->asteroid_types),
            size                        => randint(1,10),
            usable_as_starter_enabled   => 0,
        });
        say "Turned into ".$target->class;
        $colony->add_news(100, 'We are Sābēn. We have destroyed '.$target->name.'. Leave now.');
        $blownup = 1;
        last;
    }
    if ($blownup == 0) {
        say "Nothing to destroy.";
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
