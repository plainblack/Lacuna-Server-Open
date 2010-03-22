package Lacuna::DB::Building::Energy::Geo;

use Moose;
extends 'Lacuna::DB::Building::Energy';

use constant controller_class => 'Lacuna::Building::Geo';

use constant image => 'geo';

use constant name => 'Geo Energy Plant';

use constant food_to_build => 100;

use constant energy_to_build => 10;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 20;

use constant time_to_build => 120;

use constant food_consumption => 2;

use constant energy_consumption => 40;

use constant energy_production => 141;

use constant ore_consumption => 12;

use constant water_consumption => 7;

use constant waste_production => 4;



no Moose;
__PACKAGE__->meta->make_immutable;
