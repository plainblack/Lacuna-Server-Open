package Lacuna::DB::Building::Energy::Fission;

use Moose;
extends 'Lacuna::DB::Building::Energy';

use constant controller_class => 'Lacuna::Building::Fission';

use constant university_prereq => 5;

use constant image => 'fission';

use constant name => 'Fission Energy Plant';

use constant food_to_build => 100;

use constant energy_to_build => 200;

use constant ore_to_build => 200;

use constant water_to_build => 150;

use constant waste_to_build => 75;

use constant time_to_build => 1550;

use constant food_consumption => 5;

use constant energy_consumption => 70;

use constant energy_production => 450;

use constant ore_consumption => 35;

use constant water_consumption => 50;

use constant waste_production => 70;



no Moose;
__PACKAGE__->meta->make_immutable;
