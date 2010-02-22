package Lacuna::DB::Body::Planet::GasGiant::G4;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

sub image {
    return 'pg4';
}

sub chalcopyrite {
    return 1000;
}

sub sulfur {
    return 2000;
}

sub magnetite {
    return 7000;
}



no Moose;
__PACKAGE__->meta->make_immutable;

