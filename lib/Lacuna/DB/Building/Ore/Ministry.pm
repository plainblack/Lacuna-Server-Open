package Lacuna::DB::Building::Ore::Ministry;

use Moose;
extends 'Lacuna::DB::Building::Ore';

use constant controller_class => 'Lacuna::Building::MiningMinistry';

use constant university_prereq => 8;

use constant max_instances_per_planet => 1;

use constant image => 'miningministry';

use constant name => 'Mining Ministry';

use constant food_to_build => 137;

use constant energy_to_build => 139;

use constant ore_to_build => 137;

use constant water_to_build => 137;

use constant waste_to_build => 70;

use constant time_to_build => 300;

use constant food_consumption => 11;

use constant energy_consumption => 16;

use constant ore_consumption => 8;

use constant water_consumption => 13;

use constant waste_production => 1;


no Moose;
__PACKAGE__->meta->make_immutable;
