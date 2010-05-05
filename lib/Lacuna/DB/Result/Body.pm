package Lacuna::DB::Result::Body;

use Moose;
extends 'Lacuna::DB::Result::Result';
use Lacuna::Util;

__PACKAGE__->table('body');
__PACKAGE__->add_columns(
    name                    => { data_type => 'char', size => 30, is_nullable => 0 },
    star_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    usable_as_starter       => { data_type => 'int', size => 11, default_value => 0 },
    orbit                   => { data_type => 'int', size => 11, default_value => 0 },
    x                       => { data_type => 'int', size => 11, default_value => 0 }, # indexed here to speed up
    y                       => { data_type => 'int', size => 11, default_value => 0 }, # searching of planets based
    z                       => { data_type => 'int', size => 11, default_value => 0 }, # on stor location
    zone                    => { data_type => 'char', size => 16, is_nullable => 0 }, # fast index for where we are
    class                   => { data_type => 'char', size => 255, is_nullable => 0 },
    size                    => { data_type => 'int', size => 11, default_value => 0 },
);

__PACKAGE__->typecast_map(class => {
    'Lacuna::DB::Result::Body::Asteroid::A1' => 'Lacuna::DB::Result::Body::Asteroid::A1',
    'Lacuna::DB::Result::Body::Asteroid::A2' => 'Lacuna::DB::Result::Body::Asteroid::A2',
    'Lacuna::DB::Result::Body::Asteroid::A3' => 'Lacuna::DB::Result::Body::Asteroid::A3',
    'Lacuna::DB::Result::Body::Asteroid::A4' => 'Lacuna::DB::Result::Body::Asteroid::A4',
    'Lacuna::DB::Result::Body::Asteroid::A5' => 'Lacuna::DB::Result::Body::Asteroid::A5',
});

__PACKAGE__->belongs_to('star', 'Lacuna::DB::Result::Star', 'star_id');


with 'Lacuna::Role::Zoned';



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
    if ($self->isa('Lacuna::DB::Result::Body::Planet::GasGiant')) {
        $type = 'gas giant';
    }
    elsif ($self->isa('Lacuna::DB::Result::Body::Asteroid')) {
        $type = 'asteroid';
    }
    elsif ($self->isa('Lacuna::DB::Result::Body::Station')) {
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
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
