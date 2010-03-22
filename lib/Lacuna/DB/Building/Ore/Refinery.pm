package Lacuna::DB::Building::Ore::Refinery;

use Moose;
extends 'Lacuna::DB::Building::Ore';

use constant controller_class => 'Lacuna::Building::OreRefinery';

use constant building_prereq => {'Lacuna::DB::Building::Ore::Mine' => 5};

use constant max_instances_per_planet => 1;

use constant university_prereq => 5;

use constant image => 'orerefinery';

use constant name => 'Ore Refinery';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 100;

use constant time_to_build => 2000;

use constant food_consumption => 15;

use constant energy_consumption => 80;

use constant ore_consumption => 100;

use constant water_consumption => 100;

use constant waste_production => 70;



no Moose;
__PACKAGE__->meta->make_immutable;
