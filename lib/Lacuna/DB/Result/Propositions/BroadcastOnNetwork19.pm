package Lacuna::DB::Result::Propositions::BroadcastOnNetwork19;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    $self->station->add_news(200, $self->scratch->{message});
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
