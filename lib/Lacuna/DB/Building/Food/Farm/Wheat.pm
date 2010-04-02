package Lacuna::DB::Building::Food::Farm::Wheat;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

use constant controller_class => 'Lacuna::Building::Wheat';

use constant min_orbit => 2;

use constant max_orbit => 4;

use constant image => 'wheat';

use constant name => 'Wheat Farm';

use constant food_to_build => 15;

use constant energy_to_build => 100;

use constant ore_to_build => 75;

use constant water_to_build => 20;

use constant waste_to_build => 10;

use constant time_to_build => 120;

use constant food_consumption => 5;

use constant wheat_production => 112;

use constant energy_consumption => 10;

use constant ore_consumption => 10;

use constant water_consumption => 10;

use constant waste_production => 28;



no Moose;
__PACKAGE__->meta->make_immutable;
