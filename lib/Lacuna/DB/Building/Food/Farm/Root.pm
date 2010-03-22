package Lacuna::DB::Building::Food::Farm::Root;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

use constant controller_class => 'Lacuna::Building::Denton';

use constant min_orbit => 5;

use constant max_orbit => 5;

use constant image => 'roots';

use constant name => 'Denton Root Patch';

use constant food_to_build => 10;

use constant energy_to_build => 100;

use constant ore_to_build => 55;

use constant water_to_build => 10;

use constant waste_to_build => 10;

use constant time_to_build => 120;

use constant food_consumption => 5;

use constant root_production => 48;

use constant energy_consumption => 1;

use constant ore_consumption => 1;

use constant water_consumption => 8;

use constant waste_production => 7;



no Moose;
__PACKAGE__->meta->make_immutable;
