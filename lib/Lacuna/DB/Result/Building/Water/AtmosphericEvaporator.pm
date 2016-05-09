package Lacuna::DB::Result::Building::Water::AtmosphericEvaporator;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Lacuna::Constants qw(GROWTH_F INFLATION_N CONSUME_S);
extends 'Lacuna::DB::Result::Building::Water';

use constant controller_class => 'Lacuna::RPC::Building::AtmosphericEvaporator';

use constant image => 'atmosphericevaporator';

use constant name => 'Atmospheric Evaporator';

use constant prod_rate => GROWTH_F;

use constant consume_rate => CONSUME_S;

use constant cost_rate => INFLATION_N;


use constant food_to_build => 630;

use constant energy_to_build => 560;

use constant ore_to_build => 770;

use constant water_to_build => 70;

use constant waste_to_build => 140;

use constant time_to_build => 60 * 3;

use constant food_consumption => 7;

use constant energy_consumption => 63;

use constant ore_consumption => 21;

use constant water_consumption => 0;

use constant water_production => 1000;
use constant max_instances_per_planet => 2;
use constant university_prereq => 17;

use constant waste_production => 63;

sub water_production_hour {
    my ($self) = @_;
    my $base = $self->body->water * $self->water_production * $self->production_hour / 10000;
    return 0 if $base <= 0;
    return sprintf('%.0f', $base * $self->water_production_bonus);
}



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
