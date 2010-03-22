package Lacuna::DB::Building::Food::Factory::Cider;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::Cider';

use constant image => 'cider';

use constant min_orbit => 3;

use constant max_orbit => 3;

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Apple'=>1};

use constant name => 'Apple Cider Bottler';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 100;

use constant time_to_build => 200;

use constant food_consumption => 150;

use constant cider_production => 75;

use constant energy_consumption => 50;

use constant water_consumption => 50;

use constant waste_production => 100;



no Moose;
__PACKAGE__->meta->make_immutable;
