package Lacuna::DB::Result::Building::Food::Potato;

use Moose;
extends 'Lacuna::DB::Result::Building::Food';

use constant controller_class => 'Lacuna::Building::Potato';

use constant min_orbit => 3;

use constant max_orbit => 4;

use constant image => 'potato';

use constant name => 'Potato Patch';

use constant food_to_build => 10;

use constant energy_to_build => 90;

use constant ore_to_build => 56;

use constant water_to_build => 10;

use constant waste_to_build => 10;

use constant time_to_build => 120;

use constant food_consumption => 1;

use constant potato_production => 24;

use constant energy_consumption => 1;

use constant ore_consumption => 1;

use constant water_consumption => 2;

use constant waste_production => 2;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
