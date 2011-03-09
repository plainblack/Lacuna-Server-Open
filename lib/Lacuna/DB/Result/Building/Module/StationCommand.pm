package Lacuna::DB::Result::Building::Module::StationCommand;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Module';

use constant controller_class => 'Lacuna::RPC::Building::StationCommand';
use constant image => 'stationcommand';
use constant name => 'Station Command Center';
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
