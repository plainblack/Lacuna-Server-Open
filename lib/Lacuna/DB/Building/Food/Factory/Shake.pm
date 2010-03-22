package Lacuna::DB::Building::Food::Factory::Shake;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::Shake';

use constant min_orbit => 2;

use constant max_orbit => 4;

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Beeldeban'=>1};

use constant image => 'shake';

use constant name => 'Beeldeban Protein Shake Factory';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 100;

use constant time_to_build => 200;

use constant food_consumption => 150;

use constant shake_production => 100;

use constant energy_consumption => 25;

use constant ore_consumption => 5;

use constant water_consumption => 40;

use constant waste_production => 20;



no Moose;
__PACKAGE__->meta->make_immutable;
