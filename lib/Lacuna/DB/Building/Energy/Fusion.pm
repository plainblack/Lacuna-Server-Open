package Lacuna::DB::Building::Energy::Fusion;

use Moose;
extends 'Lacuna::DB::Building::Energy';

use constant controller_class => 'Lacuna::Building::Fusion';

use constant university_prereq => 9;

use constant image => 'fusion';

use constant name => 'Fusion Energy Plant';

use constant food_to_build => 270;

use constant energy_to_build => 340;

use constant ore_to_build => 320;

use constant water_to_build => 240;

use constant waste_to_build => 300;

use constant time_to_build => 350;

use constant food_consumption => 5;

use constant energy_consumption => 50;

use constant energy_production => 570;

use constant ore_consumption => 30;

use constant water_consumption => 60;

use constant waste_production => 10;


no Moose;
__PACKAGE__->meta->make_immutable;
