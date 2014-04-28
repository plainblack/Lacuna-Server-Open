package Lacuna::DB::Result::Law::Jurisdiction;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Law';

# not sure if this is still used?

#efore delete => sub {
#   my $self = shift;
#   my $star = $self->star;
#   $star->station_id(undef);
#   $star->update;
#;
#
#efore insert => sub {
#   my $self = shift;
#   my $star = $self->star;
#   $star->station_id($self->station_id);
#   $star->update;
#;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
