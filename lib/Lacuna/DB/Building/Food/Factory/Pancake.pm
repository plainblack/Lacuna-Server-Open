package Lacuna::DB::Building::Food::Factory::Pancake;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::Pancake';

use constant min_orbit => 3;

use constant max_orbit => 4;

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Potato'=>1};

use constant image => 'pancake';

use constant name => 'Potato Pancake Factory';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 100;

use constant time_to_build => 2000;

use constant food_consumption => 150;

use constant pancake_production => 90;

use constant energy_consumption => 25;

use constant water_consumption => 25;

use constant waste_production => 25;



no Moose;
__PACKAGE__->meta->make_immutable;
