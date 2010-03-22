package Lacuna::DB::Building::Propulsion;

use Moose;
extends 'Lacuna::DB::Building';

use constant controller_class => 'Lacuna::Building::Propulsion';

use constant building_prereq => {'Lacuna::DB::Building::Shipyard'=>1};

use constant max_instances_per_planet => 1;

use constant image => 'propulsion';

use constant name => 'Propulsion System Factory';

use constant food_to_build => 150;

use constant energy_to_build => 225;

use constant ore_to_build => 225;

use constant water_to_build => 100;

use constant waste_to_build => 150;

use constant time_to_build => 600;

use constant food_consumption => 10;

use constant energy_consumption => 100;

use constant ore_consumption => 100;

use constant water_consumption => 50;

use constant waste_production => 75;


no Moose;
__PACKAGE__->meta->make_immutable;
