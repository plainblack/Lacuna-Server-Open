package Lacuna::DB::Result::Ships::Fighter;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::University',  level => 99 };
use constant food_cost      => 1000;
use constant water_cost     => 2600;
use constant energy_cost    => 16200;
use constant ore_cost       => 14200;
use constant time_cost      => 14600;
use constant waste_cost     => 4200;
use constant pilotable      => 1;

sub arrive {
    my ($self) = @_;
    $self->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
