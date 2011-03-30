package Lacuna::DB::Result::Building::LCOTd;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
with 'Lacuna::Role::LCOT';

use constant controller_class => 'Lacuna::RPC::Building::LCOTd';
use constant image => 'lcoth';
use constant name => 'Lost City of Tyleon (D)';

before 'can_demolish' => sub {
    my $self = shift;
    my $e = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTe');
    if (defined $e) {
        confess [1013, 'You have to demolish your Lost City of Tyleon (E) before you can demolish your Lost City of Tyleon (D).'];
    }
};

before can_build => sub {
    my $self = shift;
    my $c = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTc');
    unless (defined $c) {
        confess [1013, 'You must have a Lost City of Tyleon (C) before you can build Lost City of Tyleon (D).'];
    }
    unless ($self->x == $c->x + 1 && $self->y == $c->y) {
        confess [1013, 'Lost City of Tyleon (D) must be placed to the right of the Lost City of Tyleon (C).'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
