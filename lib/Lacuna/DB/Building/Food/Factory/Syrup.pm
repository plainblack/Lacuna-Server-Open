package Lacuna::DB::Building::Food::Factory::Syrup;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::Syrup';

use constant image => 'syrup';

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Algae'=>1};

use constant name => 'Algae Syrup Bottler';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 100;

use constant time_to_build => 2000;

use constant food_consumption => 150;

use constant syrup_production => 100;

use constant energy_consumption => 75;

use constant water_consumption => 25;

use constant waste_production => 75;



no Moose;
__PACKAGE__->meta->make_immutable;
