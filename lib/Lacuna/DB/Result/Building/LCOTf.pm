package Lacuna::DB::Result::Building::LCOTf;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
with 'Lacuna::Role::LCOT';

use constant controller_class => 'Lacuna::RPC::Building::LCOTf';
use constant image => 'lcotf';
use constant name => 'Lost City of Tyleon (F)';

before 'can_demolish' => sub {
    my $self = shift;
    my $g = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTg');
    if (defined $g) {
        confess [1013, 'You have to demolish your Lost City of Tyleon (G) before you can demolish your Lost City of Tyleon (F).'];
    }
};

before can_build => sub {
    my $self = shift;
    my $e = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTe');
    unless (defined $e) {
        confess [1013, 'You must have a Lost City of Tyleon (E) before you can build Lost City of Tyleon (F).'];
    }
    unless ($self->x == $e->x && $self->y == $e->y - 1) {
        confess [1013, 'Lost City of Tyleon (F) must be placed below the Lost City of Tyleon (E).'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
