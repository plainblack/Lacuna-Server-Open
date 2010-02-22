package Lacuna::Building::Security;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/security';
}

sub model_class {
    return 'Lacuna::DB::Building::Security';
}

no Moose;
__PACKAGE__->meta->make_immutable;

