package Lacuna::DB::Building::Energy::Singularity;

use Moose;
extends 'Lacuna::DB::Building::Energy';

use constant controller_class => 'Lacuna::Building::Singularity';

use constant image => 'singularity';

use constant university_prereq => 15;

use constant name => 'Singularity Energy Plant';

use constant food_to_build => 1000;

use constant energy_to_build => 1105;

use constant ore_to_build => 1400;

use constant water_to_build => 1100;

use constant waste_to_build => 1475;

use constant time_to_build => 1200;

use constant food_consumption => 5;

use constant energy_consumption => 70;

use constant energy_production => 380;

use constant ore_consumption => 4;

use constant water_consumption => 5;

use constant waste_production => 18;



no Moose;
__PACKAGE__->meta->make_immutable;
