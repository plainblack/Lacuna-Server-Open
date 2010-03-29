package Lacuna::DB::Building::Ore::Mine;

use Moose;
extends 'Lacuna::DB::Building::Ore';

use constant controller_class => 'Lacuna::Building::Mine';

use constant image => 'mine';

use constant name => 'Mine';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 10;

use constant water_to_build => 100;

use constant waste_to_build => 85;

use constant time_to_build => 120;

use constant food_consumption => 10;

use constant energy_consumption => 10;

use constant ore_production => 120;

use constant ore_consumption => 5;

use constant water_consumption => 10;

use constant waste_production => 20;

no Moose;
__PACKAGE__->meta->make_immutable;
