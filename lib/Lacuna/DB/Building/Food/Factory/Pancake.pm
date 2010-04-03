package Lacuna::DB::Building::Food::Factory::Pancake;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::Pancake';

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Potato'=>5};

use constant image => 'pancake';

use constant name => 'Potato Pancake Factory';

use constant food_to_build => 125;

use constant energy_to_build => 125;

use constant ore_to_build => 125;

use constant water_to_build => 125;

use constant waste_to_build => 50;

use constant time_to_build => 200;

use constant food_consumption => 30;

use constant pancake_production => 30;

use constant energy_consumption => 5;

use constant ore_consumption => 5;

use constant water_consumption => 5;

use constant waste_production => 15;



no Moose;
__PACKAGE__->meta->make_immutable;
