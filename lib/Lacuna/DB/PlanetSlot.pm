package Lacuna::DB::PlanetSlot;

use Moose;
extends 'SimpleDB::Class::Item';

__PACKAGE__->set_domain_name('planet_slot');
__PACKAGE__->add_attributes(
    date_created    => { isa => 'DateTime' },
    planet_id       => { isa => 'Str' },
    x               => { isa => 'Int' },
    y               => { isa => 'Int' },
    building_class  => { isa => 'Str' },
    building_id     => { isa => 'Str' },
);

__PACKAGE__->belongs_to('planet', 'Lacuna::DB::Planet', 'planet_id');

sub has_building {
    my $self = shift;
    return ($self->building_class ne '' && $self->building_id ne '');
}

sub building {
    my $self = shift;
    if ($self->has_building) {
        return $self->domain->simpledb->determine_domain_instance($self->building_class)->find($self->building_id);
    }
    else {
        return undef;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
