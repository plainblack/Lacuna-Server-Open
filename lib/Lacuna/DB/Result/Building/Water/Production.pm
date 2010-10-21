package Lacuna::DB::Result::Building::Water::Production;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Water';

use constant controller_class => 'Lacuna::RPC::Building::WaterProduction';

use constant university_prereq => 1;

use constant image => 'waterproduction';

use constant name => 'Water Production Plant';

use constant food_to_build => 120;

use constant energy_to_build => 300;

use constant ore_to_build => 350;

use constant water_to_build => 130;

use constant waste_to_build => 20;

use constant time_to_build => 100;

use constant food_consumption => 8;

use constant energy_consumption => 40;

use constant ore_consumption => 40;

use constant water_production => 80;

use constant waste_production => 8;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
