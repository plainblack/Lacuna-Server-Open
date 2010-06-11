package Lacuna::DB::Result;

use parent qw/DBIx::Class/;

__PACKAGE__->load_components('TimeStamp', 'InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');

__PACKAGE__->table('noexist_basetable');
__PACKAGE__->add_columns(
    id      => { data_type => 'int', size => 11, is_auto_increment => 1 },
);
__PACKAGE__->set_primary_key('id');

# override default DBIx::Class constructor to set defaults from schema
sub new {
    my $class = shift;
    my $self = $class->next::method(@_);
    foreach my $col ($self->result_source->columns) {
        my $default = $self->result_source->column_info($col)->{default_value};
        $self->$col($default) if (defined $default && !defined $self->$col());
    }
    return $self;
}

