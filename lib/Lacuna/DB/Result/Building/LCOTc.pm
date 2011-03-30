package Lacuna::DB::Result::Building::LCOTc;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
with 'Lacuna::Role::LCOT';

use constant controller_class => 'Lacuna::RPC::Building::LCOTc';
use constant image => 'lcoti';
use constant name => 'Lost City of Tyleon (C)';

before 'can_demolish' => sub {
    my $self = shift;
    my $d = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTd');
    if (defined $d) {
        confess [1013, 'You have to demolish your Lost City of Tyleon (D) before you can demolish your Lost City of Tyleon (C).'];
    }
};

before can_build => sub {
    my $self = shift;
    my $b = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTb');
    unless (defined $b) {
        confess [1013, 'You must have a Lost City of Tyleon (B) before you can build Lost City of Tyleon (C).'];
    }
    unless ($self->x == $b->x && $self->y == $b->y + 1) {
        confess [1013, 'Lost City of Tyleon (C) must be placed above of the Lost City of Tyleon (B).'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
