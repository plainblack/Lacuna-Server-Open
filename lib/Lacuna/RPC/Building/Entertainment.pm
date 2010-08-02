package Lacuna::RPC::Building::Entertainment;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/entertainment';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::EntertainmentDistrict';
}

no Moose;
__PACKAGE__->meta->make_immutable;

