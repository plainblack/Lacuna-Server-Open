package Lacuna::DB::Building::Food::Farm::Lapis;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

use constant controller_class => 'Lacuna::Building::Lapis';

use constant min_orbit => 2;

use constant max_orbit => 2;

use constant image => 'lapis';

use constant name => 'Lapis Orchard';

use constant food_to_build => 15;

use constant energy_to_build => 71;

use constant ore_to_build => 75;

use constant water_to_build => 140;

use constant waste_to_build => 5;

use constant time_to_build => 130;

use constant food_consumption => 1;

use constant lapis_production => 44;

use constant energy_consumption => 2;

use constant ore_consumption => 5;

use constant water_consumption => 5;

use constant waste_production => 13;



no Moose;
__PACKAGE__->meta->make_immutable;
