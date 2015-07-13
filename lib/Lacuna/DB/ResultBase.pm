package Lacuna::DB::ResultBase;

use namespace::autoclean -except => ['meta'];

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('TimeStamp', 'InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');

# override default DBIx::Class constructor to set defaults from schema
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    foreach my $col ($self->result_source->columns) {
        my $default = $self->result_source->column_info($col)->{default_value};
        $self->$col($default) if (defined $default && !defined $self->$col());
    }
    return $self;
}

sub random {
    my $self = shift;
    return $self->search( undef, { order_by => 'rand()' })->first;
}

1;
