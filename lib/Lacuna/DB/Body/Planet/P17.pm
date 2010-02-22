package Lacuna::DB::Body::Planet::P17;

use Moose;
extends 'Lacuna::DB::Body::Planet';


sub image {
    return 'p17';
}

sub water {
    return 10000;
}

# resource concentrations

sub trona {
    return 3900;
}

sub methane {
    return 1900;
}

sub magnetite {
    return 4200;
}


no Moose;
__PACKAGE__->meta->make_immutable;

