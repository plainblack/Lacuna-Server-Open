package Lacuna::DB::Planet;

use Moose;
extends 'SimpleDB::Class::Domain';

__PACKAGE__->set_name('planet');
__PACKAGE__->add_attributes({
    name            => { isa => 'Str' },
    date_created    => { isa => 'DateTime' },
    empire_id       => { isa => 'Str' },
    star_id         => { isa => 'Str' },
    size            => { isa => 'Int' },
    type            => { isa => 'Str' },
    is_gas_giant    => { isa => 'Str', default=>0 },
    is_asteroid     => { isa => 'Str', default=>0 },
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
    mineral_stored  => { isa => 'Serial' },
    mineral_per     => { isa => 'Serial' },
    food_storage    => { isa => 'Int' },
    food_stored     => { isa => 'Serial' },
    food_per        => { isa => 'Serial' },
});

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');
__PACKAGE__->belongs_to('star', 'Lacuna::DB::Star', 'star_id');
__PACKAGE__->has_many('slots', 'Lacuna::DB::Slot', 'planet_id');

no Moose;
__PACKAGE__->meta->make_immutable;
