package Lacuna::RPC::Building::Lapis;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/lapis';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Lapis';
}

no Moose;
__PACKAGE__->meta->make_immutable;

