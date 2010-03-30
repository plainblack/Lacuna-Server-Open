package Lacuna::DB::Body;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util;

__PACKAGE__->set_domain_name('body');
__PACKAGE__->add_attributes(
    name            => { isa => 'Str', 
        trigger => sub {
            my ($self, $new, $old) = @_;
            $self->name_cname(Lacuna::Util::cname($new));
        },
    },
    name_cname              => { isa => 'Str' },
    star_id                 => { isa => 'Str' },
    usable_as_starter       => { isa => 'Str', default=>'No'},
    orbit                   => { isa => 'Int' },
    x                       => { isa => 'Int' }, # indexed here to speed up
    y                       => { isa => 'Int' }, # searching of planets based
    z                       => { isa => 'Int' }, # on stor location
    class                   => { isa => 'Str' },
);

__PACKAGE__->belongs_to('star', 'Lacuna::DB::Star', 'star_id');
__PACKAGE__->recast_using('class');


sub lock {
    my $self = shift;
    return $self->simpledb->cache->set('planet_contention_lock',$self->id,{locked=>1},60); # lock it
}

sub is_locked {
    my $self = shift;
    return eval{$self->simpledb->cache->get('planet_contention_lock',$self->id)->{locked}};
}

sub image {
    confess "override me";
}

sub get_type {
    my ($self) = @_;
    my $type = 'habitable planet';
    if ($self->isa('Lacuna::DB::Body::Planet::GasGiant')) {
        $type = 'gas giant';
    }
    elsif ($self->isa('Lacuna::DB::Body::Asteroid')) {
        $type = 'asteroid';
    }
    elsif ($self->isa('Lacuna::DB::Body::Station')) {
        $type = 'space station';
    }
    return $type;
}

sub get_status {
    my ($self) = @_;
    my %out = (
        name            => $self->name,
        image           => $self->image,
        x               => $self->x,
        y               => $self->y,
        z               => $self->z,
        orbit           => $self->orbit,
        type            => $self->get_type,
        star_id         => $self->star_id,
        star_name       => $self->star->name,
        id              => $self->id,
        alignment       => 'none',
    );
    return \%out;
}


no Moose;
__PACKAGE__->meta->make_immutable;
