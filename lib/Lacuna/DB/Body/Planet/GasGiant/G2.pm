package Lacuna::DB::Body::Planet::GasGiant::G2;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

sub image {
    return 'pg2';
}



sub galena {
    return 7000;
}

sub bauxite {
    return 2000;
}

sub goethite {
    return 1000;
}


no Moose;
__PACKAGE__->meta->make_immutable;

