package Lacuna::DB::Building::Food::Factory::Pie;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::Pie';

use constant image => 'pie';

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Lapis'=>5};

use constant name => 'Lapis Pie Bakery';

use constant food_to_build => 135;

use constant energy_to_build => 135;

use constant ore_to_build => 135;

use constant water_to_build => 135;

use constant waste_to_build => 100;

use constant time_to_build => 200;

use constant food_consumption => 150;

use constant pie_production => 150;

use constant energy_consumption => 25;

use constant ore_consumption => 25;

use constant water_consumption => 20;

use constant waste_production => 70;



no Moose;
__PACKAGE__->meta->make_immutable;
