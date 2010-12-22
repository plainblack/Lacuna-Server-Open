package Lacuna::VirtualContainer;

use Moose;
use utf8;
no warnings qw(uninitialized);


has payload => (
    is          => 'rw',
    required    => 1,
);

with 'Lacuna::Role::Container';

sub update {};
sub id { 1 };

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);