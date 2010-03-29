package Lacuna::DB::Building::Food::Factory::Soup;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::Soup';

use constant image => 'cannery';

use constant min_orbit => 4;

use constant max_orbit => 4;

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Bean'=>5};

use constant name => 'Amalgus Bean Soup Cannery';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 100;

use constant time_to_build => 200;

use constant food_consumption => 150;

use constant soup_production => 110;

use constant energy_consumption => 20;

use constant ore_consumption => 3;

use constant water_consumption => 30;

use constant waste_production => 25;



no Moose;
__PACKAGE__->meta->make_immutable;
