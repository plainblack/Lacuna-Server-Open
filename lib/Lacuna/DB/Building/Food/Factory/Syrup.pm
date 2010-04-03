package Lacuna::DB::Building::Food::Factory::Syrup;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::Syrup';

use constant image => 'syrup';

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Algae'=>5};

use constant name => 'Algae Syrup Bottler';

use constant food_to_build => 150;

use constant energy_to_build => 150;

use constant ore_to_build => 150;

use constant water_to_build => 150;

use constant waste_to_build => 95;

use constant time_to_build => 200;

use constant food_consumption => 30;

use constant syrup_production => 30;

use constant energy_consumption => 15;

use constant ore_consumption => 1;

use constant water_consumption => 5;

use constant waste_production => 21;



no Moose;
__PACKAGE__->meta->make_immutable;
