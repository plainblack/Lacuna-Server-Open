package Lacuna::DB::Body::Planet::P20;

use Moose;
extends 'Lacuna::DB::Body::Planet';


sub image {
    return 'p20';
}

sub water {
    return 2608;
}

# resource concentrations
sub rutile {
    return 2800;
}

sub chromite {
    return 1400;
}
sub galena {
    return 3100;
}
sub bauxite {
    return 900;
}
sub magnetite {
    return 1800;
}


no Moose;
__PACKAGE__->meta->make_immutable;

