package Lacuna::DB::Result::Building::Module::CulinaryInstitute;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Module';
with 'Lacuna::Role::Influencer';

use constant controller_class => 'Lacuna::RPC::Building::CulinaryInstitute';
use constant image => 'culinaryinstitute';
use constant name => 'Culinary Institute';
use constant max_instances_per_planet => 1;
use constant food_consumption => 160;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
