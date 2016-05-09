package Lacuna::Role::LCOT;

use Moose::Role;

use Lacuna::Constants qw(GROWTH_F CONSUME_S INFLATION_F WASTE_S WASTE_F HAPPY_F HAPPY_S TINFLATE_F);

use constant prod_rate => GROWTH_F;
use constant consume_rate => CONSUME_S;
use constant cost_rate => INFLATION_F;
use constant waste_prod_rate => WASTE_S;
use constant waste_consume_rate => WASTE_F;
use constant happy_prod_rate => HAPPY_F;
use constant happy_consume_rate => HAPPY_S;
use constant time_inflation => TINFLATE_F;

use constant food_to_build => 5000;
use constant energy_to_build => 5000;
use constant ore_to_build => 5000;
use constant water_to_build => 5000;
use constant waste_to_build => 2000;
use constant time_to_build => 60 * 5;
use constant food_consumption => 120;
use constant energy_consumption => 120;
use constant ore_consumption => 120;
use constant water_consumption => 120;
use constant waste_production => 80;
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
