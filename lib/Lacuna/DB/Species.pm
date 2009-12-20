package Lacuna::DB::Species;

use Moose;
extends 'SimpleDB::Class::Domain';

__PACKAGE__->set_name('species');
__PACKAGE__->add_attributes({
    name                    => { isa => 'Str' },
    date_created            => { isa => 'DateTime' },
    created_by              => { isa => 'Str' },
    habitable_orbits        => { isa => 'Int' },
    construction_affinity   => { isa => 'Int' },
    espionage_affinity      => { isa => 'Int' },
    research_affinity       => { isa => 'Int' },
    management_affinity     => { isa => 'Int' },
    farming_affinity        => { isa => 'Int' },
    mining_affinity         => { isa => 'Int' },
    science_affinity        => { isa => 'Int' },
    environment_affinity    => { isa => 'Int' },
    political_affinity      => { isa => 'Int' },
});

__PACKAGE__->belongs_to('creator', 'Lacuna::DB::Empire', 'created_by');
__PACKAGE__->has_many('empires', 'Lacuna::DB::Empire', 'species_id');

no Moose;
__PACKAGE__->meta->make_immutable;
