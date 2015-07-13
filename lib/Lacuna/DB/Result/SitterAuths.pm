package Lacuna::DB::Result::SitterAuths;

use Moose;
use utf8;
use DateTime;

# no "id" column.
extends 'Lacuna::DB::ResultBase';

__PACKAGE__->load_components('TimeStamp', 'InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');

__PACKAGE__->table('sitter_auths');
__PACKAGE__->add_columns(
    baby_id   => { data_type => 'int',      is_nullable => 0 },
    sitter_id => { data_type => 'int',      is_nullable => 0 },
    expiry    => { data_type => 'datetime', is_nullable => 0 },
);
__PACKAGE__->set_primary_key('baby_id','sitter_id');

__PACKAGE__->belongs_to('baby', 'Lacuna::DB::Result::Empire', 'baby_id', { on_delete => 'cascade' });
__PACKAGE__->belongs_to('sitter', 'Lacuna::DB::Result::Empire', 'sitter_id', { on_delete => 'cascade' });

sub _new_auth_date
{
    Lacuna->db->resultset("SitterAuths")->new_auth_date;
}

sub reauthorise
{
    my ($self) = @_;

    $self->expiry($self->_new_auth_date);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
