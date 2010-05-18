package Lacuna::DB::Result::Building::Food::Cheese;

use Moose;
extends 'Lacuna::DB::Result::Building::Food';

use constant controller_class => 'Lacuna::RPC::Building::Cheese';

use constant image => 'cheese';

use constant building_prereq => {'Lacuna::DB::Result::Building::Food::Dairy'=>5};

use constant name => 'Cheese Maker';

use constant food_to_build => 175;

use constant energy_to_build => 175;

use constant ore_to_build => 175;

use constant water_to_build => 175;

use constant waste_to_build => 90;

use constant time_to_build => 200;

use constant food_consumption => 30;

use constant cheese_production => 30;

use constant energy_consumption => 15;

use constant ore_consumption => 1;

use constant water_consumption => 15;

use constant waste_production => 31;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
