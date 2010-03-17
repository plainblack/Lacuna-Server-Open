package Lacuna::DB::Building::Food::Farm::Apple;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

use constant controller_class => 'Lacuna::Building::Apple';

use constant building_prereq => {'Lacuna::DB::Building::PlanetaryCommand'=>5};

use constant min_orbit => 3;

use constant max_orbit => 3;

use constant image => 'apples';

use constant name => 'Apple Orchard';

use constant food_to_build => 10;

use constant energy_to_build => 100;

use constant ore_to_build => 55;

use constant water_to_build => 10;

use constant waste_to_build => 5;

use constant time_to_build => 600;

use constant food_consumption => 5;

use constant apple_production => 46;

use constant energy_consumption => 1;

use constant ore_consumption => 1;

use constant water_consumption => 9;

use constant waste_production => 16;

use constant waste_consumption => 3;



no Moose;
__PACKAGE__->meta->make_immutable;
