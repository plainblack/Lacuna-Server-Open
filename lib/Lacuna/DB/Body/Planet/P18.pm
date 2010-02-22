package Lacuna::DB::Body::Planet::P18;

use Moose;
extends 'Lacuna::DB::Body::Planet';


sub image {
    return 'p18';
}

sub water {
    return 7600;
}

# resource concentrations

sub chromite {
    return 3200;
}

sub uraninite {
    return 2600;
}

sub bauxite {
    return 4200;
}


no Moose;
__PACKAGE__->meta->make_immutable;

