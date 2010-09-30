package Lacuna::RPC::Building::TempleOfTheDrajilites;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/templeofthedrajilites';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::TempleOfTheDrajilites';
}


sub view_planet {
    my ($self, $session_id, $building_id, $planet_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $planet = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($planet_id);
    
    unless (defined $planet) {
        confess [1002, 'Could not locate that planet.'];
    }
    unless ($planet->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        confess [2009, 'The Temple can only view nearby planets.'];
    }
    unless ($planet->star_id eq $building->body->star_id) {
        confess [2009, 'That planet is too far away.'];
    }
    
    my @map;
    my $buildings = $planet->buildings;
    while (my $building = $buildings->next) {
        push @map, {
            image   => $building->image_level,
            x       => $building->x,
            y       => $building->y,
        };
    }
    return {
        status  => $self->format_status($empire, $building->body),
        map     => {
            surface_image   => $planet->surface,
            buildings       => \@map
        },
    };
}

sub list_planets {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    
    my @planets;
    my $bodies = $building->body->star->bodies;
    while (my $body = $bodies->next) {
        next unless $body->isa('Lacuna::DB::Result::Map::Body::Planet');
        push @planets, {
            id      => $body->id,
            name    => $body->name,
        };
    }
    
    return {
        status  => $self->format_status($empire, $building->body),
        planets => \@planets,
    };
}

__PACKAGE__->register_rpc_method_names(qw(view_planet list_planets));

no Moose;
__PACKAGE__->meta->make_immutable;

