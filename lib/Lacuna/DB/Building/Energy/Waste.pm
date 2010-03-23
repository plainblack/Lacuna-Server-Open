package Lacuna::DB::Building::Energy::Waste;

use Moose;
extends 'Lacuna::DB::Building::Energy';

use constant controller_class => 'Lacuna::Building::WasteEnergy';

use constant image => 'wasteenergy';

use constant university_prereq => 3;

use constant name => 'Waste Energy Plant';

use constant food_to_build => 100;

use constant energy_to_build => 10;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 20;

use constant time_to_build => 150;

use constant food_consumption => 10;

use constant energy_consumption => 110;

use constant energy_production => 255;

use constant ore_consumption => 5;

use constant water_consumption => 10;

use constant waste_consumption => 100;

use constant waste_production => 10;



no Moose;
__PACKAGE__->meta->make_immutable;
