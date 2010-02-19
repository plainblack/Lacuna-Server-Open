package Lacuna::DB::Body::Planet::GasGiant::G1;

use Moose;
extends 'Lacuna::DB::Body::Planet::GasGiant';

sub image {
    return 'pg1';
}


sub rutile {
    return 7000;
}

sub chromite {
    return 2000;
}

sub chalcopyrite {
    return 1000;
}


no Moose;
__PACKAGE__->meta->make_immutable;

