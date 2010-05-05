package Lacuna::DB::Building::Food::Reserve;

use Moose;
extends 'Lacuna::DB::Building::Food';

use constant controller_class => 'Lacuna::Building::FoodReserve';

use constant image => 'food-reserve';

use constant name => 'Food Reserve';

use constant university_prereq => 1;

use constant food_to_build => 45;

use constant energy_to_build => 45;

use constant ore_to_build => 45;

use constant water_to_build => 45;

use constant waste_to_build => 45;

use constant time_to_build => 120;

use constant food_consumption => 1;

use constant energy_consumption => 4;

use constant water_consumption => 1;

use constant waste_production => 1;

use constant food_storage => 1000;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
