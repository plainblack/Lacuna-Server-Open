package Lacuna::Role::LCOT;

use Moose::Role;

use constant food_to_build => 4250;
use constant energy_to_build => 4250;
use constant ore_to_build => 4250;
use constant water_to_build => 4250;
use constant waste_to_build => 1000;
use constant time_to_build => 60 * 3;
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

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(ref $self, 1)) {
        return $orig->($self, $body);
    }
    confess [1013,"You can't build the Lost City of Tyleon without knowledge left behind by the Great Race."];
};



1;
