package Lacuna::DB;

use Moose;
extends qw/DBIx::Class::Schema/;

__PACKAGE__->load_namespaces();

no Moose;
__PACKAGE__->meta->make_immutable;
