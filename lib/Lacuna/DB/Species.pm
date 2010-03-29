package Lacuna::DB::Species;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util;
use Lacuna::Verify;

__PACKAGE__->set_domain_name('species');
__PACKAGE__->add_attributes(
    name                    => { isa => 'Str', 
        trigger => sub {
            my ($self, $new, $old) = @_;
            $self->name_cname(Lacuna::Util::cname($new));
        } ,
    },
    empire_id               => { isa => 'Str' },
    name_cname              => { isa => 'Str' },
    description             => { isa => 'Str' },
    habitable_orbits        => { isa => 'ArrayRefOfInt' },
    manufacturing_affinity  => { isa => 'Int' }, # cost of building new stuff
    deception_affinity      => { isa => 'Int' }, # spying ability
    research_affinity       => { isa => 'Int' }, # cost of upgrading
    management_affinity     => { isa => 'Int' }, # speed to build
    farming_affinity        => { isa => 'Int' }, # food
    mining_affinity         => { isa => 'Int' }, # minerals
    science_affinity        => { isa => 'Int' }, # energy, propultion, and other tech
    environmental_affinity  => { isa => 'Int' }, # waste and water
    political_affinity      => { isa => 'Int' }, # happiness
    trade_affinity          => { isa => 'Int' }, # speed of cargoships, and amount of cargo hauled
    growth_affinity         => { isa => 'Int' }, # price and speed of colony ships, and planetary command center start level
);

__PACKAGE__->has_many('empires', 'Lacuna::DB::Empire', 'species_id', mate => 'species');
__PACKAGE__->belongs_to('creator', 'Lacuna::DB::Empire', 'empire_id');


no Moose;
__PACKAGE__->meta->make_immutable;
