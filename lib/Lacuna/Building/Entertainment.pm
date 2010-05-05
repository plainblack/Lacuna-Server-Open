package Lacuna::Building::Entertainment;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/entertainment';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::EntertainmentDistrict';
}

no Moose;
__PACKAGE__->meta->make_immutable;

