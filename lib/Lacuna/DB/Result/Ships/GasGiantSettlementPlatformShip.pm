package Lacuna::DB::Result::Ships::GasGiantSettlementPlatformShip;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';


use constant pilotable      => 1;

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::GasGiantLab',  level => 1 };
use constant base_food_cost      => 36000;
use constant base_water_cost     => 90000;
use constant base_energy_cost    => 340000;
use constant base_ore_cost       => 250000;
use constant base_time_cost      => 48000;
use constant base_waste_cost     => 53000;
use constant base_speed     => 500;
use constant base_stealth   => 0;
use constant base_hold_size => 0;

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Colonization));
};

sub arrive {
    my ($self) = @_;
    $self->note_arrival;
    if ($self->direction eq 'out') {
        my $lab = $self->body->get_building_of_class('Lacuna::DB::Result::Building::GasGiantLab');
        $self->foreign_body->add_plan('Lacuna::DB::Result::Building::Permanent::GasGiantPlatform', 1, (defined $lab) ? $lab->level : 0);
        $self->delete;
    }
    else {
        $self->land;
    }
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to gas giants.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Planet::GasGiant'));
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
