package Lacuna::RPC::Building::LibraryOfJith;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/libraryofjith';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::LibraryOfJith';
}

no Moose;
__PACKAGE__->meta->make_immutable;

