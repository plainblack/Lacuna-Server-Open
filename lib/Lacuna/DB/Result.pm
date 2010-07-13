package Lacuna::DB::Result;

use Moose;
use namespace::autoclean -except;

extends 'DBIx::Class::Core';

__PACKAGE__->load_components('TimeStamp', 'InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');

__PACKAGE__->table('noexist_basetable');
__PACKAGE__->add_columns(
    id      => { data_type => 'int', size => 11, is_auto_increment => 1 },
);
__PACKAGE__->set_primary_key('id');

# override default DBIx::Class constructor to set defaults from schema
sub BUILD {
    my $self = shift;
    foreach my $col ($self->result_source->columns) {
        my $default = $self->result_source->column_info($col)->{default_value};
        $self->$col($default) if (defined $default && !defined $self->$col());
    }
    return $self;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;