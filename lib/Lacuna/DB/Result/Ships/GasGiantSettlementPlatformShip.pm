package Lacuna::DB::Result::Ships::GasGiantSettlementPlatformShip;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';


use constant pilotable      => 1;

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::GasGiantLab',  level => 1 };
use constant base_food_cost      => 36000;
use constant base_water_cost     => 90000;
use constant base_energy_cost    => 540000;
use constant base_ore_cost       => 450000;
use constant base_time_cost      => 48000;
use constant base_waste_cost     => 123000;
use constant base_speed     => 500;
use constant base_stealth   => 0;
use constant base_hold_size => 0;

sub arrive {
    my ($self) = @_;
    if ($self->direction eq 'out') {
        my $lab = $self->body->get_building_of_class('Lacuna::DB::Result::Building::GasGiantLab');
        if (defined $lab) {
            $self->foreign_body->add_plan('Lacuna::DB::Result::Building::Permanent::GasGiantPlatform', 1, $lab->level);
        }
    }
    else {
        $self->land;
    }
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to gas giants.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Planet::GasGiant'));
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
