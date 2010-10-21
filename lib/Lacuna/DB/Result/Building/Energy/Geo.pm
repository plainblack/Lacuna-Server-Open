package Lacuna::DB::Result::Building::Energy::Geo;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Energy';

use constant controller_class => 'Lacuna::RPC::Building::Geo';

use constant image => 'geo';

use constant name => 'Geo Energy Plant';

use constant food_to_build => 140;

use constant energy_to_build => 18;

use constant ore_to_build => 140;

use constant water_to_build => 100;

use constant waste_to_build => 20;

use constant time_to_build => 60;

use constant food_consumption => 1;

use constant energy_consumption => 10;

use constant energy_production => 60;

use constant ore_consumption => 2;

use constant water_consumption => 1;

use constant waste_production => 1;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
