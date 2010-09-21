package Lacuna::DB::Result::Ships::Snark;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq             => { class=> 'Lacuna::DB::Result::Building::MunitionsLab',  level => 5 };
use constant base_food_cost     => 18000;
use constant base_water_cost    => 46800;
use constant base_energy_cost   => 145000;
use constant base_ore_cost      => 195030;
use constant base_time_cost     => 58400;
use constant base_waste_cost    => 39600;
use constant base_speed         => 1000;
use constant base_stealth       => 2000;
use constant base_hold_size     => 0;


around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(War));
};

sub arrive {
    my ($self) = @_;
    unless ($self->trigger_defense) {
        $self->damage_building;
    }
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to planets.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Planet'));
    confess [1013, 'Can only be sent to inhabited planets.'] unless ($target->empire_id);
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
