package Lacuna::DB::Building::SpacePort;

use Moose;
extends 'Lacuna::DB::Building';
use Lacuna::Constants qw(SHIP_TYPES);


__PACKAGE__->add_attributes(
    probe_count                         => { isa => 'Int', default => 0 },
    colony_ship_count                   => { isa => 'Int', default => 0 },
    spy_pod_count                       => { isa => 'Int', default => 0 },
    cargo_ship_count                    => { isa => 'Int', default => 0 },
    space_station_count                 => { isa => 'Int', default => 0 },
    smuggler_ship_count                 => { isa => 'Int', default => 0 },
    mining_platform_ship_count          => { isa => 'Int', default => 0 },
    terraforming_platform_ship_count    => { isa => 'Int', default => 0 },
    gas_giant_settlement_ship_count     => { isa => 'Int', default => 0 },
);

sub shipyards {
    my $self = shift;
    return $self->simpledb->domain('Lacuna::DB::Building::Shipyard')->search(
        where => { body_id => $self->body_id, class => 'Lacuna::DB::Building::Shipyard' }
        );
}

sub check_for_completed_ships {
    my $self = shift;
    my $shipyards = $self->shipyards;
    while (my $shipyard = $shipyards->next) {
        $shipyard->check_for_completed_ships($self);
    }
}

sub ships_docked {
    my $self = shift;
    my $tally;
    foreach my $type (SHIP_TYPES) {
        my $docked = $type.'_count';
        $tally += $self->$docked;
    }
    return $tally;
}

sub docks_available {
    my $self = shift;
    return ($self->level * 2) - $self->ships_docked;
}

sub is_full {
    my ($self) = @_;
    return $self->docks_available ? 0 : 1;
}

sub add_ship {
    my ($self, $type) = @_;
    my $count = $type.'_count';
    $self->$count( $self->$count + 1);
}


use constant controller_class => 'Lacuna::Building::SpacePort';

use constant university_prereq => 3;

use constant image => 'spaceport';

use constant name => 'Space Port';

use constant food_to_build => 800;

use constant energy_to_build => 900;

use constant ore_to_build => 500;

use constant water_to_build => 500;

use constant waste_to_build => 400;

use constant time_to_build => 8500;

use constant food_consumption => 100;

use constant energy_consumption => 100;

use constant ore_consumption => 120;

use constant water_consumption => 150;

use constant waste_production => 100;


no Moose;
__PACKAGE__->meta->make_immutable;
