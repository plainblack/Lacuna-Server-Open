package Lacuna::DB::Result::Building::Module::IBS;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Module';
with 'Lacuna::Role::Influencer';

use constant controller_class => 'Lacuna::RPC::Building::IBS';
use constant image => 'ibs';
use constant name => 'Interstellar Broadcast System';
use constant max_instances_per_planet => 1;
use constant energy_consumption => 160;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
