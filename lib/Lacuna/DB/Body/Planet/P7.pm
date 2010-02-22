package Lacuna::DB::Body::Planet::P7;

use Moose;
extends 'Lacuna::DB::Body::Planet';

sub image {
    return 'p7';
}

sub water {
    return 4700;
}

# resource concentrations

sub chalcopyrite {
    return 2800;
}

sub bauxite {
    return 2700;
}

sub goethite {
    return 2400;
}

sub gypsum {
    return 2100;
}



no Moose;
__PACKAGE__->meta->make_immutable;

