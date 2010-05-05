package Lacuna::DB::Building::Ore::Refinery;

use Moose;
extends 'Lacuna::DB::Building::Ore';

use constant controller_class => 'Lacuna::Building::OreRefinery';

use constant building_prereq => {'Lacuna::DB::Building::Ore::Mine' => 5};

use constant max_instances_per_planet => 1;

use constant image => 'orerefinery';

use constant name => 'Ore Refinery';

use constant food_to_build => 147;

use constant energy_to_build => 148;

use constant ore_to_build => 147;

use constant water_to_build => 148;

use constant waste_to_build => 100;

use constant time_to_build => 250;

use constant food_consumption => 5;

use constant energy_consumption => 30;

use constant water_consumption => 14;

use constant waste_production => 16;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
