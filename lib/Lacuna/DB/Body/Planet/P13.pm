package Lacuna::DB::Body::Planet::P13;

use Moose;
extends 'Lacuna::DB::Body::Planet';


sub image {
    return 'p13';
}

sub water {
    return 3800;
}

# resource concentrations
sub rutile {
    return 2100;
}

sub chromite {
    return 1400;
}

sub chalcopyrite {
    return 1300;
}

sub galena {
    return 2200;
}

sub kerogen {
    return 1500;
}

sub anthracite {
    return 1500;
}


no Moose;
__PACKAGE__->meta->make_immutable;

