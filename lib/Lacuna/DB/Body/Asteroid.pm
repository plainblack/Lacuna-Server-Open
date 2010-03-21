package Lacuna::DB::Body::Asteroid;

use Moose;
extends 'Lacuna::DB::Body';
use Lacuna::Constants qw(ORE_TYPES);


__PACKAGE__->add_attributes(
    size            => { isa => 'Int' },
);

around 'get_status' => sub {
    my ($orig, $self) = @_;
    my $out = $orig->($self);
    my %ore;
    foreach my $type (ORE_TYPES) {
        $ore{$type} = $self->$type();
    }
    $out->{size}            = $self->size;
    $out->{ore}             = \%ore;
    return $out;
};

# resource concentrations
use constant rutile => 1;

use constant chromite => 1;

use constant chalcopyrite => 1;

use constant galena => 1;

use constant gold => 1;

use constant uraninite => 1;

use constant bauxite => 1;

use constant goethite => 1;

use constant halite => 1;

use constant gypsum => 1;

use constant trona => 1;

use constant kerogen => 1;

use constant methane => 1;

use constant anthracite => 1;

use constant sulfur => 1;

use constant zircon => 1;

use constant monazite => 1;

use constant fluorite => 1;

use constant beryl => 1;

use constant magnetite => 1;

use constant water => 0;

no Moose;
__PACKAGE__->meta->make_immutable;

