package Lacuna::RPC::Building::TempleOfTheDrajilites;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/templeofthedrajilites';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::TempleOfTheDrajilites';
}

no Moose;
__PACKAGE__->meta->make_immutable;

