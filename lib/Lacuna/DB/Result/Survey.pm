package Lacuna::DB::Result::Survey;

use Moose;
use utf8;
use DateTime;

# no "id" column.
extends 'Lacuna::DB::ResultBase';

__PACKAGE__->load_components('TimeStamp', 'InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');

__PACKAGE__->table('survey');
__PACKAGE__->add_columns(
    empire_id   => { data_type => 'int',    is_nullable => 0 },
    choice      => { data_type => 'int',    is_nullable => 1 },
    comment     => { data_type => 'text',   is_nullable => 1 },
);
__PACKAGE__->set_primary_key('empire_id');

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id', { on_delete => 'cascade' });

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
