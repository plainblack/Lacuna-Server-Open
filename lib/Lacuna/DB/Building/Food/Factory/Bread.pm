package Lacuna::DB::Building::Food::Factory::Bread;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::Bread';

use constant min_orbit => 2;

use constant max_orbit => 4;

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Wheat'=>1};

use constant image => 'bread';

use constant name => 'Bread Bakery';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 100;

use constant time_to_build => 200;

use constant food_consumption => 150;

use constant bread_production => 75;

use constant energy_consumption => 50;

use constant water_consumption => 25;

use constant waste_production => 28;



no Moose;
__PACKAGE__->meta->make_immutable;
