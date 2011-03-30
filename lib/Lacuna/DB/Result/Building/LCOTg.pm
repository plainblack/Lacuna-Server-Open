package Lacuna::DB::Result::Building::LCOTg;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
with 'Lacuna::Role::LCOT';

use constant controller_class => 'Lacuna::RPC::Building::LCOTg';
use constant image => 'lcotc';
use constant name => 'Lost City of Tyleon (G)';

before 'can_demolish' => sub {
    my $self = shift;
    my $h = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTh');
    if (defined $h) {
        confess [1013, 'You have to demolish your Lost City of Tyleon (H) before you can demolish your Lost City of Tyleon (G).'];
    }
};

before can_build => sub {
    my $self = shift;
    my $f = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTf');
    unless (defined $f) {
        confess [1013, 'You must have a Lost City of Tyleon (F) before you can build Lost City of Tyleon (G).'];
    }
    unless ($self->x == $f->x && $self->y == $f->y - 1) {
        confess [1013, 'Lost City of Tyleon (G) must be placed below the Lost City of Tyleon (F).'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
