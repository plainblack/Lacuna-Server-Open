package Lacuna::DB::Body;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util;

__PACKAGE__->set_domain_name('body');
__PACKAGE__->add_attributes(
    name            => { isa => 'Str', 
        trigger => sub {
            my ($self, $new, $old) = @_;
            $self->cname(Lacuna::Util::cname($new));
        },
    },
    cname           => { isa => 'Str' },
    star_id         => { isa => 'Str' },
    orbit           => { isa => 'Int' },
    x               => { isa => 'Int' }, # indexed here to speed up
    y               => { isa => 'Int' }, # searching of planets based
    z               => { isa => 'Int' }, # on stor location
    class           => { isa => 'Str' },
);

__PACKAGE__->belongs_to('star', 'Lacuna::DB::Star', 'star_id');
__PACKAGE__->recast_using('class');

sub image {
    confess "override me";
}

sub water {
    return 1;
}

# resource concentrations
sub rutile {
    return 1;
}

sub chromite {
    return 1;
}

sub chalcopyrite {
    return 1;
}

sub galena {
    return 1;
}

sub bauxite {
    return 1;
}

sub goethite {
    return 1;
}

sub halite {
    return 1;
}

sub gypsum {
    return 1;
}

sub sulfur {
    return 1;
}

sub magnetite {
    return 1;
}

sub trona {
    return 1;
}

sub uraninite {
    return 1;
}

sub methane {
    return 1;
}

sub kerogen {
    return 1;
}

sub anthracite {
    return 1;
}

sub fluorite {
    return 1;
}

sub beryl {
    return 1;
}

sub zircon {
    return 1;
}

sub monazite {
    return 1;
}

sub gold {
    return 1;
}



no Moose;
__PACKAGE__->meta->make_immutable;
