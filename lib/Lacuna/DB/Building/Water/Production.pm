package Lacuna::DB::Building::Water::Production;

use Moose;
extends 'Lacuna::DB::Building::Water';

use constant controller_class => 'Lacuna::Building::WaterProduction';

use constant university_prereq => 1;

use constant image => 'waterproduction';

use constant name => 'Water Production Plant';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 20;

use constant time_to_build => 1150;

use constant food_consumption => 10;

use constant energy_consumption => 100;

use constant ore_consumption => 100;

use constant water_production => 170;

use constant waste_production => 20;



no Moose;
__PACKAGE__->meta->make_immutable;
