package Lacuna::DB::Item::PlanetSlot;

use Moose;
extends 'SimpleDB::Class::Item';


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
