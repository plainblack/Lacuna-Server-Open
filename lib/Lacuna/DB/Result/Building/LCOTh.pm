package Lacuna::DB::Result::Building::LCOTh;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
with 'Lacuna::Role::LCOT';

use constant controller_class => 'Lacuna::RPC::Building::LCOTh';
use constant image => 'lcotd';
use constant name => 'Lost City of Tyleon (H)';

before 'can_demolish' => sub {
    my $self = shift;
    my $i = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTi');
    if (defined $i) {
        confess [1013, 'You have to demolish your Lost City of Tyleon (I) before you can demolish your Lost City of Tyleon (H).'];
    }
};

before can_build => sub {
    my $self = shift;
    my $g = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTg');
    unless (defined $g) {
        confess [1013, 'You must have a Lost City of Tyleon (G) before you can build Lost City of Tyleon (H).'];
    }
    unless ($self->x == $g->x - 1 && $self->y == $g->y) {
        confess [1013, 'Lost City of Tyleon (H) must be placed to the left of the Lost City of Tyleon (G).'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
