package Lacuna::DB;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends qw/DBIx::Class::Schema/;

__PACKAGE__->load_namespaces();

no Moose;
__PACKAGE__->meta->make_immutable;
