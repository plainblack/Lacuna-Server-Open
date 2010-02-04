package Lacuna::DB::BuildQueue;

use Moose;
extends 'SimpleDB::Class::Item';

__PACKAGE__->set_domain_name('build_queue');
__PACKAGE__->add_attributes(
    date_created        => { isa => 'DateTime' },
    date_complete       => { isa => 'DateTime' },
    empire_id           => { isa => 'Str' },
    building_class      => { isa => 'Str' },
    building_id         => { isa => 'Str' },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');

sub building {
    my ($self) = @_;
    return $self->simpledb->domain($self->building_class)->find($self->building_id);
}

no Moose;
__PACKAGE__->meta->make_immutable;
