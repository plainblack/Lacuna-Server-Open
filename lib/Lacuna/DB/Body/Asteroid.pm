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


no Moose;
__PACKAGE__->meta->make_immutable;

