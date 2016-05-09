package Lacuna::DB::Result::Building::Permanent::Grove;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::Grove';

use constant image => 'grove';

use constant name => 'Grove of Trees';
use constant max_instances_per_planet => 9;

use constant water_to_build => 1;
use constant time_to_build => 1;
use constant energy_production => 10; 

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
