package Lacuna::DB::PlanetSlot;

use Moose;
extends 'SimpleDB::Class::Domain';

__PACKAGE__->set_name('planet_slot');
__PACKAGE__->add_attributes({
    date_created    => { isa => 'DateTime' },
    planet_id       => { isa => 'Str' },
    x               => { isa => 'Int' },
    y               => { isa => 'Int' },
    building_class  => { isa => 'Str' },
    building_id     => { isa => 'Str' },
});

__PACKAGE__->belongs_to('planet', 'Lacuna::DB::Planet', 'planet_id');
__PACKAGE__->item_class('Lacuna::DB::Item::PlanetSlot');

no Moose;
__PACKAGE__->meta->make_immutable;
