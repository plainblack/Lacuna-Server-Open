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
        if (defined $default && !defined $self->$col()) {
            $self->$col($default);
        }

        # if the class has a method for _default_$col, call it to determine the default
        # in code.
        if (!defined $self->$col() && (my $can = $self->can("_default_$col"))) {
            $self->$col($can->($self));
        }
    }
    return $self;
}

sub random {
    my $self = shift;
    return $self->search( undef, { order_by => 'rand()' })->first;
}

1;
