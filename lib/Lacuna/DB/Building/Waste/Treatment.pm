package Lacuna::DB::Building::Waste::Treatment;

use Moose;
extends 'Lacuna::DB::Building::Waste';

use constant controller_class => 'Lacuna::Building::WasteTreatment';

use constant image => 'wastetreatment';

use constant university_prereq => 3;

use constant name => 'Waste Treatment Center';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 20;

use constant time_to_build => 300;

use constant food_consumption => 5;

use constant energy_consumption => 10;

use constant energy_production => 30;

use constant ore_consumption => 10;

use constant ore_production => 30;

use constant water_consumption => 10;

use constant water_production => 30;

use constant waste_consumption => 110;

use constant waste_production => 10;



no Moose;
__PACKAGE__->meta->make_immutable;
