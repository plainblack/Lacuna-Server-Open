package Lacuna::DB::Species;

use Moose;
extends 'SimpleDB::Class::Item';

__PACKAGE__->set_domain_name('species');
__PACKAGE__->add_attributes({
    name                    => { isa => 'Str' },
    date_created            => { isa => 'DateTime' },
    created_by              => { isa => 'Str' },
    habitable_orbits        => { isa => 'Int' },
    construction_affinity   => { isa => 'Int' }, # cost of building new stuff
    espionage_affinity      => { isa => 'Int' }, # spying ability
    research_affinity       => { isa => 'Int' }, # cost of upgradings
    management_affinity     => { isa => 'Int' }, # speed to build
    farming_affinity        => { isa => 'Int' }, # food
    mining_affinity         => { isa => 'Int' }, # minerals
    science_affinity        => { isa => 'Int' }, # energy
    environment_affinity    => { isa => 'Int' }, # waste
    political_affinity      => { isa => 'Int' }, # happiness
    trade_affinity          => { isa => 'Int' }, # speed of cargoships, and amount of cargo hauled
});

# colonization affinity
# water affinity

__PACKAGE__->belongs_to('creator', 'Lacuna::DB::Empire', 'created_by');
__PACKAGE__->has_many('empires', 'Lacuna::DB::Empire', 'species_id');

no Moose;
__PACKAGE__->meta->make_immutable;
