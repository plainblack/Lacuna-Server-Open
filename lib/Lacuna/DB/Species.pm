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

sub find_home_planet {
    my ($self) = @_;
    my $possible_planets = $self->simpledb->domain('Lacuna::DB::Body::Planet')->search(
        where       => {
            usable_as_starter   => ['!=', 'No'],
            orbit               => ['in',@{$self->habitable_orbits}],
            x               => ['between', ($self->get_min_inhabited('x') - 1), ($self->get_max_inhabited('x') + 1)],
            y               => ['between', ($self->get_min_inhabited('y') - 1), ($self->get_max_inhabited('y') + 1)],
            z               => ['between', ($self->get_min_inhabited('z') - 1), ($self->get_max_inhabited('z') + 1)],
        },
        order_by    => 'usable_as_starter',
        limit       => 1,
        consistent  => 1,
        );
    my $home_planet = $possible_planets->next;
    unless (defined $home_planet) {
        confess [1002, 'Could not find a home planet.'];
    }
    return $home_planet;
}

sub get_max_inhabited {
    my ($self, $axis) = @_;
    return $self->simpledb->domain('Lacuna::DB::Body::Planet')->max($axis, where=>{empire_id=>['!=','None']});
}

sub get_min_inhabited {
    my ($self, $axis) = @_;
    return $self->simpledb->domain('Lacuna::DB::Body::Planet')->min($axis, where=>{empire_id=>['!=','None']});
}


no Moose;
__PACKAGE__->meta->make_immutable;
