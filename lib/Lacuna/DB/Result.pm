package Lacuna::DB::Result;

use Moose;
extends qw/DBIx::Class/;

__PACKAGE__->load_components('DynamicSubclass', 'InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');

__PACKAGE__->table('noexist_basetable');
__PACKAGE__->add_columns(
    id      => {
        data_type           => 'int',
        size                => 11,
        is_auto_increment   => 1,
    },
);
__PACKAGE__->set_primary_key('id');

no Moose;
__PACKAGE__->meta->make_immutable;