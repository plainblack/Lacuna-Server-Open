package Lacuna::DB::Result::Building::LuxuryHousing;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(GROWTH_F INFLATION_N CONSUME_S);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness));
};

use constant controller_class => 'Lacuna::RPC::Building::LuxuryHousing';

use Lacuna::Constants qw(INFLATION_F CONSUME_S WASTE_F HAPPY_F TINFLATE_F);

use constant consume_rate => CONSUME_S;
use constant cost_rate => INFLATION_F;
use constant waste_prod_rate => WASTE_F;
use constant happy_prod_rate => HAPPY_F;
use constant time_inflation => TINFLATE_F;

use constant university_prereq => 11;

use constant image => 'luxuryhousing';

use constant name => 'Luxury Housing';

use constant food_to_build => 640;

use constant energy_to_build => 640;

use constant ore_to_build => 760;

use constant water_to_build => 760;

use constant waste_to_build => 250;

use constant time_to_build => 250;

use constant food_consumption => 75;

use constant energy_consumption => 75;

use constant ore_consumption => 20;

use constant water_consumption => 85;

use constant waste_production => 60;

use constant happiness_production => 500;
use constant max_instances_per_planet => 2;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
