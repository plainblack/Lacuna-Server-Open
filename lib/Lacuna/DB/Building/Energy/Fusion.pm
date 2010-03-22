package Lacuna::DB::Building::Energy::Fusion;

use Moose;
extends 'Lacuna::DB::Building::Energy';

use constant controller_class => 'Lacuna::Building::Fusion';

use constant university_prereq => 10;

use constant image => 'fusion';

use constant name => 'Fusion Energy Plant';

use constant food_to_build => 500;

use constant energy_to_build => 650;

use constant ore_to_build => 575;

use constant water_to_build => 480;

use constant waste_to_build => 2000;

use constant time_to_build => 350;

use constant food_consumption => 5;

use constant energy_consumption => 50;

use constant energy_production => 517;

use constant ore_consumption => 30;

use constant water_consumption => 60;

use constant waste_production => 8;


no Moose;
__PACKAGE__->meta->make_immutable;
