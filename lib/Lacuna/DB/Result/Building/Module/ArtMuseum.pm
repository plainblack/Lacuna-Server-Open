package Lacuna::DB::Result::Building::Module::ArtMuseum;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Module';
with 'Lacuna::Role::Influencer';

use constant controller_class => 'Lacuna::RPC::Building::ArtMuseum';
use constant image => 'artmuseum';
use constant name => 'Art Museum';
use constant max_instances_per_planet => 1;
use constant ore_consumption => 160;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
