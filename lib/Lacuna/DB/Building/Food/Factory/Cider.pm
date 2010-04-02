package Lacuna::DB::Building::Food::Factory::Cider;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::Cider';

use constant image => 'cider';

use constant min_orbit => 3;

use constant max_orbit => 3;

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Apple'=>5};

use constant name => 'Apple Cider Bottler';

use constant food_to_build => 160;

use constant energy_to_build => 170;

use constant ore_to_build => 150;

use constant water_to_build => 170;

use constant waste_to_build => 50;

use constant time_to_build => 200;

use constant food_consumption => 150;

use constant cider_production => 150;

use constant energy_consumption => 50;

use constant ore_consumption => 10;

use constant water_consumption => 140;

use constant waste_production => 200;



no Moose;
__PACKAGE__->meta->make_immutable;
