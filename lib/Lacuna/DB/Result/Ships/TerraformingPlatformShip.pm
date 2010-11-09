package Lacuna::DB::Result::Ships::TerraformingPlatformShip;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::TerraformingLab',  level => 1 };
use constant base_food_cost      => 96000;
use constant base_water_cost     => 180000;
use constant base_energy_cost    => 310000;
use constant base_ore_cost       => 226000;
use constant base_time_cost      => 45000;
use constant base_waste_cost     => 45000;
use constant base_speed     => 550;
use constant base_stealth   => 0;
use constant base_hold_size => 0;
use constant pilotable      => 1;

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Colonization));
};

sub arrive {
    my ($self) = @_;
    if ($self->direction eq 'out') {
        my $lab = $self->body->get_building_of_class('Lacuna::DB::Result::Building::TerraformingLab');
        $self->foreign_body->add_plan('Lacuna::DB::Result::Building::Permanent::TerraformingPlatform', 1, (defined $lab) ? $lab->level : 0);
        $self->delete;
    }
    else {
        $self->land;
    }
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to planets.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Planet'));
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
