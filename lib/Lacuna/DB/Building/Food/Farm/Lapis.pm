package Lacuna::DB::Building::Food::Farm::Lapis;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

use constant controller_class => 'Lacuna::Building::Lapis';

use constant building_prereq => {'Lacuna::DB::Building::Water::Storage'=>1};

use constant min_orbit => 2;

use constant max_orbit => 2;

use constant image => 'lapis';

use constant name => 'Lapis Orchard';

use constant food_to_build => 10;

use constant energy_to_build => 100;

use constant ore_to_build => 55;

use constant water_to_build => 10;

use constant waste_to_build => 5;

use constant time_to_build => 130;

use constant food_consumption => 5;

use constant lapis_production => 174;

use constant energy_consumption => 11;

use constant ore_consumption => 20;

use constant water_consumption => 20;

use constant waste_production => 50;



no Moose;
__PACKAGE__->meta->make_immutable;
