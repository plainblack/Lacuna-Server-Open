package Lacuna::DB::Building::Food::Factory::CornMeal;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::CornMeal';

use constant image => 'meal';

use constant min_orbit => 2;

use constant max_orbit => 3;

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Corn'=>5};

use constant name => 'Corn Meal Grinder';

use constant food_to_build => 140;

use constant energy_to_build => 140;

use constant ore_to_build => 140;

use constant water_to_build => 150;

use constant waste_to_build => 100;

use constant time_to_build => 200;

use constant food_consumption => 150;

use constant meal_production => 150;

use constant energy_consumption => 25;

use constant ore_consumption => 25;

use constant water_consumption => 25;

use constant waste_production => 75;



no Moose;
__PACKAGE__->meta->make_immutable;
