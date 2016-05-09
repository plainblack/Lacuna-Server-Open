package Lacuna::DB::Result::Building::Energy::Singularity;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Energy';

use Lacuna::Constants qw(GROWTH_F INFLATION_F CONSUME_N WASTE_S WASTE_N);

use constant prod_rate => GROWTH_F;
use constant consume_rate => CONSUME_N;
use constant cost_rate => INFLATION_F;
use constant waste_prod_rate => WASTE_S;
use constant waste_consume_rate => WASTE_N;

use constant controller_class => 'Lacuna::RPC::Building::Singularity';

use constant image => 'singularity';

use constant university_prereq => 15;

use constant name => 'Singularity Energy Plant';

use constant food_to_build => 1000;

use constant energy_to_build => 1105;

use constant ore_to_build => 1400;

use constant water_to_build => 1100;

use constant waste_to_build => 1475;

use constant time_to_build => 600;

use constant food_consumption => 20;

use constant energy_consumption => 100;

use constant energy_production => 800;

use constant ore_consumption => 10;

use constant water_consumption => 10;
use constant max_instances_per_planet => 2;

use constant waste_production => 23;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
