package Lacuna::DB::Building::Food::Factory::Cheese;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::Cheese';

use constant image => 'cheese';

use constant min_orbit => 3;

use constant max_orbit => 3;

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Dairy'=>1};

use constant name => 'Cheese Maker';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 100;

use constant time_to_build => 2000;

use constant food_consumption => 150;

use constant cheese_production => 100;

use constant energy_consumption => 75;

use constant ore_consumption => 2;

use constant water_consumption => 75;

use constant waste_production => 125;



no Moose;
__PACKAGE__->meta->make_immutable;
