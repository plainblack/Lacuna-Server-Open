package Lacuna::DB;

use Moose;
extends 'SimpleDB::Class';

__PACKAGE__->load_namespaces;

no Moose;
__PACKAGE__->meta->make_immutable;
