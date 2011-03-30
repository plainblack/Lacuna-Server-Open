package Lacuna::DB::Result::Building::LCOTb;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
with 'Lacuna::Role::LCOT';

use constant controller_class => 'Lacuna::RPC::Building::LCOTb';
use constant image => 'lcotb';
use constant name => 'Lost City of Tyleon (B)';

before 'can_demolish' => sub {
    my $self = shift;
    my $c = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTc');
    if (defined $c) {
        confess [1013, 'You have to demolish your Lost City of Tyleon (C) before you can demolish your Lost City of Tyleon (B).'];
    }
};

before can_build => sub {
    my $self = shift;
    my $a = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTa');
    unless (defined $a) {
        confess [1013, 'You must have a Lost City of Tyleon (A) before you can build Lost City of Tyleon (B).'];
    }
    unless ($self->x == $a->x - 1 && $self->y == $a->y) {
        confess [1013, 'Lost City of Tyleon (B) must be placed to the left of the Lost City of Tyleon (A).'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
