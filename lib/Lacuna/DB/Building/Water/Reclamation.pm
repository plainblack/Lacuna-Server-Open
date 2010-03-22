package Lacuna::DB::Building::Water::Reclamation;

use Moose;
extends 'Lacuna::DB::Building::Water';

use constant controller_class => 'Lacuna::Building::WaterReclamation';

use constant university_prereq => 3;

use constant image => 'waterreclamation';

use constant name => 'Water Reclamation Facility';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 20;

use constant time_to_build => 950;

use constant food_consumption => 5;

use constant energy_consumption => 5;

use constant ore_consumption => 5;

use constant water_production => 200;

use constant waste_consumption => 100;



no Moose;
__PACKAGE__->meta->make_immutable;
