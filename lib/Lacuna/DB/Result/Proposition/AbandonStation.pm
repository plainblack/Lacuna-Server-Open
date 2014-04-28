package Lacuna::DB::Result::Proposition::AbandonStation;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    $self->pass_extra_message('Station shutdown has been initiated.');
#    $self->station->sanitize;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
