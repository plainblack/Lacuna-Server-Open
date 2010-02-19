package Lacuna::DB::Body::Planet::P16;

use Moose;
extends 'Lacuna::DB::Body::Planet';


sub image {
    return 'p16';
}

sub water {
    return 1000;
}

# resource concentrations
sub rutile {
    return 600;
}

sub chromite {
    return 400;
}

sub galena {
    return 200;
}

sub uraninite {
    return 800;
}

sub goethite {
    return 300;
}

sub halite {
    return 700;
}

sub trona {
    return 900;
}

sub sulfur {
    return 100;
}

sub kerogen {
    return 2700;
}

sub anthracite {
    return 3300;
}


no Moose;
__PACKAGE__->meta->make_immutable;

