package Lacuna::DB::Building::Food::Farm::Malcud;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

use constant controller_class => 'Lacuna::Building::Malcud';

use constant image => 'malcud';

use constant name => 'Malcud Fungus Farm';

use constant food_to_build => 10;

use constant energy_to_build => 100;

use constant ore_to_build => 55;

use constant water_to_build => 30;

use constant waste_to_build => 20;

use constant time_to_build => 115;

use constant food_consumption => 5;

use constant fungus_production => 31;

use constant energy_consumption => 1;

use constant ore_production => 4;

use constant water_consumption => 4;

use constant waste_consumption => 1;



no Moose;
__PACKAGE__->meta->make_immutable;
