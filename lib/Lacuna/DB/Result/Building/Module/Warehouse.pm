package Lacuna::DB::Result::Building::Module::Warehouse;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Module';

use constant controller_class => 'Lacuna::RPC::Building::Warehouse';
use constant image => 'warehouse';
use constant name => 'Warehouse';
use constant food_storage   => 6000;
use constant water_storage  => 6000;
use constant ore_storage    => 6000;
use constant energy_storage => 6000;
use constant energy_consumption => 80;
use constant water_consumption => 80;
use constant food_consumption => 80;
use constant ore_consumption => 80;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
