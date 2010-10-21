package Lacuna::RPC::Building::TerraformingPlatform;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/terraformingplatform';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform';
}

no Moose;
__PACKAGE__->meta->make_immutable;

