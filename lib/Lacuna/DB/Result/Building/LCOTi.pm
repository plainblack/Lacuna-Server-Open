package Lacuna::DB::Result::Building::LCOTi;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
with 'Lacuna::Role::LCOT';

use constant controller_class => 'Lacuna::RPC::Building::LCOTi';
use constant image => 'lcote';
use constant name => 'Lost City of Tyleon (I)';

before can_build => sub {
    my $self = shift;
    my $h = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTh');
    unless (defined $h) {
        confess [1013, 'You must have a Lost City of Tyleon (H) before you can build Lost City of Tyleon (I).'];
    }
    unless ($self->x == $h->x - 1 && $self->y == $h->y) {
        confess [1013, 'Lost City of Tyleon (I) must be placed to the left of the Lost City of Tyleon (H).'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
