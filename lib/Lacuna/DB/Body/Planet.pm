package Lacuna::DB::Body::Planet;

use Moose;
extends 'Lacuna::DB::Body';

__PACKAGE__->add_attributes(
    size            => { isa => 'Int' },
    empire_id       => { isa => 'Str', default=>'None' },
    happiness_per   => { isa => 'Int', default=>0 },
    happiness       => { isa => 'Int', default=>0 },
    waste_per       => { isa => 'Int', default=>0 },
    waste_stored    => { isa => 'Int', default=>0 },
    waste_storage   => { isa => 'Int', default=>0 },
    energy_per      => { isa => 'Int', default=>0 },
    energy_stored   => { isa => 'Int', default=>0 },
    energy_storage  => { isa => 'Int', default=>0 },
    water_per       => { isa => 'Int', default=>0 },
    water_stored    => { isa => 'Int', default=>0 },
    water_storage   => { isa => 'Int', default=>0 },
    mineral_storage => { isa => 'Int', default=>0 },
#    mineral_stored  => { isa => 'HashRef' },
#    mineral_per     => { isa => 'HashRef' },
    food_storage    => { isa => 'Int', default=>0 },
#    food_stored     => { isa => 'HashRef' },
#    food_per        => { isa => 'HashRef' },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');

no Moose;
__PACKAGE__->meta->make_immutable;
