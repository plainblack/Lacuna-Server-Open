package Lacuna::Role::LCOT;

use Moose::Role;

use constant food_to_build => 7000;
use constant energy_to_build => 7000;
use constant ore_to_build => 7000;
use constant water_to_build => 7000;
use constant waste_to_build => 700;
use constant time_to_build => 60 * 2;
use constant food_consumption => 50;
use constant energy_consumption => 50;
use constant ore_consumption => 50;
use constant water_consumption => 50;
use constant waste_production => 50;
use constant max_instances_per_planet => 1;

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Water Food Waste Energy Ore Storage Happiness));
};

sub image_level {
    my $self = shift;
    return $self->image;
}




1;
