package Lacuna::DB::Result::Building::Food::Farm::Dairy;

use Moose;
extends 'Lacuna::DB::Result::Building::Food::Farm';

use constant controller_class => 'Lacuna::Building::Dairy';

use constant building_prereq => {'Lacuna::DB::Result::Building::Food::Farm::Corn'=>5};


use constant min_orbit => 3;

use constant max_orbit => 3;

use constant image => 'dairy';

use constant name => 'Dairy Farm';

use constant food_to_build => 200;

use constant energy_to_build => 100;

use constant ore_to_build => 150;

use constant water_to_build => 200;

use constant waste_to_build => 50;

use constant time_to_build => 220;

use constant food_consumption => 8;

use constant milk_production => 68;

use constant energy_consumption => 6;

use constant ore_consumption => 1;

use constant water_consumption => 10;

use constant waste_production => 33;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
