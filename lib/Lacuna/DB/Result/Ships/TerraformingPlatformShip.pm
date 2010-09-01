package Lacuna::DB::Result::Ships::TerraformingPlatformShip;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::TerraformingLab',  level => 1 };
use constant base_food_cost      => 96000;
use constant base_water_cost     => 180000;
use constant base_energy_cost    => 510000;
use constant base_ore_cost       => 426000;
use constant base_time_cost      => 45000;
use constant base_waste_cost     => 90000;
use constant base_speed     => 550;
use constant base_stealth   => 0;
use constant base_hold_size => 0;
use constant pilotable      => 1;

sub arrive {
    my ($self) = @_;
    if ($self->direction eq 'out') {
        my $lab = $self->body->get_building_of_class('Lacuna::DB::Result::Building::TerraformingLab');
        if (defined $lab) {
            $self->foreign_body->add_plan('Lacuna::DB::Result::Building::Permanent::TerraformingPlatform', 1, $lab->level);
        }
    }
    else {
        $self->land;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
