package Lacuna::DB::Result::Ships::Scow;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => { class=> 'Lacuna::DB::Result::Building::Waste::Sequestration',  level => 10 };
use constant base_food_cost         => 2000;
use constant base_water_cost        => 5200;
use constant base_energy_cost       => 32400;
use constant base_ore_cost          => 28400;
use constant base_time_cost         => 14600;
use constant base_waste_cost        => 8400;
use constant base_speed             => 400;
use constant base_combat            => 500;
use constant base_stealth           => 0;
use constant base_hold_size         => 2100;
use constant build_tags             => [qw(War Trade)];

with "Lacuna::Role::Ship::Send::PlanetAndStar";
with "Lacuna::Role::Ship::Arrive::TriggerDefense";
with "Lacuna::Role::Ship::Arrive::DumpWaste";

sub _build_hostile_action {
    my $self = shift;
    if ($self->foreign_body->empire && $self->foreign_body->empire_id != $self->body->empire_id) {
        return 1;
    }
    else {
        return 0;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
