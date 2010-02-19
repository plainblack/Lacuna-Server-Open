package Lacuna::DB::Body::Planet::P11;

use Moose;
extends 'Lacuna::DB::Body::Planet';



sub image {
    return 'p11';
}

sub water {
    return 3800;
}


# resource concentrations

sub chromite {
    return 1000;
}

sub galena {
    return 1000;
}

sub uraninite {
    return 1000;
}

sub goethite {
    return 1000;
}

sub gypsum {
    return 1000;
}

sub kerogen {
    return 1000;
}

sub anthracite {
    return 1000;
}

sub zircon {
    return 1000;
}

sub fluorite {
    return 1000;
}

sub magnetite {
    return 1000;
}

no Moose;
__PACKAGE__->meta->make_immutable;

