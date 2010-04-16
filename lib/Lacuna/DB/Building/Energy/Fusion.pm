package Lacuna::DB::Building::Energy::Fusion;

use Moose;
extends 'Lacuna::DB::Building::Energy';

use constant controller_class => 'Lacuna::Building::Fusion';

use constant university_prereq => 9;

use constant image => 'fusion';

use constant name => 'Fusion Reactor';

use constant food_to_build => 270;

use constant energy_to_build => 340;

use constant ore_to_build => 320;

use constant water_to_build => 240;

use constant waste_to_build => 300;

use constant time_to_build => 350;

use constant food_consumption => 1;

use constant energy_consumption => 12;

use constant energy_production => 143;

use constant ore_consumption => 7;

use constant water_consumption => 15;

use constant waste_production => 2;


no Moose;
__PACKAGE__->meta->make_immutable;
