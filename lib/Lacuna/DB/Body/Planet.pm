package Lacuna::DB::Planet;

use Moose;
extends 'Lacuna::DB::Body';

__PACKAGE__->add_attributes(
    size            => { isa => 'Int' },
    empire_id       => { isa => 'Str' },
    happiness_per   => { isa => 'Int' },
    happiness       => { isa => 'Int' },
    waste_per       => { isa => 'Int' },
    waste_stored    => { isa => 'Int' },
    waste_storage   => { isa => 'Int' },
    energy_per      => { isa => 'Int' },
    energy_stored   => { isa => 'Int' },
    energy_storage  => { isa => 'Int' },
    water_per       => { isa => 'Int' },
    water_stored    => { isa => 'Int' },
    water_storage   => { isa => 'Int' },
    mineral_storage => { isa => 'Int' },
    mineral_stored  => { isa => 'HashRef' },
    mineral_per     => { isa => 'HashRef' },
    food_storage    => { isa => 'Int' },
    food_stored     => { isa => 'HashRef' },
    food_per        => { isa => 'HashRef' },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');
__PACKAGE__->has_many('slots', 'Lacuna::DB::Slot', 'planet_id');

no Moose;
__PACKAGE__->meta->make_immutable;
