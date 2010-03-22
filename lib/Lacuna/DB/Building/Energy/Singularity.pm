package Lacuna::DB::Building::Energy::Singularity;

use Moose;
extends 'Lacuna::DB::Building::Energy';

use constant controller_class => 'Lacuna::Building::Singularity';

use constant image => 'singularity';

use constant university_prereq => 17;

use constant name => 'Singularity Energy Plant';

use constant food_to_build => 1100;

use constant energy_to_build => 1205;

use constant ore_to_build => 2350;

use constant water_to_build => 1190;

use constant waste_to_build => 1475;

use constant time_to_build => 13000;

use constant food_consumption => 27;

use constant energy_consumption => 350;

use constant energy_production => 799;

use constant ore_consumption => 23;

use constant water_consumption => 25;

use constant waste_production => 1;



no Moose;
__PACKAGE__->meta->make_immutable;
