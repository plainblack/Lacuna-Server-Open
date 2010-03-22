package Lacuna::DB::Building::Food::Reserve;

use Moose;
extends 'Lacuna::DB::Building::Food';

use constant controller_class => 'Lacuna::Building::FoodReserve';

use constant image => 'food-reserve';

use constant name => 'Food Reserve';

use constant food_to_build => 45;

use constant energy_to_build => 45;

use constant ore_to_build => 45;

use constant water_to_build => 45;

use constant waste_to_build => 45;

use constant time_to_build => 1000;

use constant food_consumption => 1;

use constant energy_consumption => 10;

use constant water_consumption => 1;

use constant waste_production => 1;

use constant food_storage => 1500;



no Moose;
__PACKAGE__->meta->make_immutable;
