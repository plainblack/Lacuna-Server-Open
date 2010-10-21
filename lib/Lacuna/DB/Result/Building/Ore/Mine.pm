package Lacuna::DB::Result::Building::Ore::Mine;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Ore';

use constant controller_class => 'Lacuna::RPC::Building::Mine';

use constant image => 'mine';

use constant name => 'Mine';

use constant food_to_build => 85;

use constant energy_to_build => 100;

use constant ore_to_build => 10;

use constant water_to_build => 100;

use constant waste_to_build => 85;

use constant time_to_build => 60;

use constant food_consumption => 2;

use constant energy_consumption => 2;

use constant ore_production => 30;

use constant ore_consumption => 1;

use constant water_consumption => 2;

use constant waste_production => 5;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
