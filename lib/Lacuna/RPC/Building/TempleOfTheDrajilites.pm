package Lacuna::RPC::Building::TempleOfTheDrajilites;

use Moose;
use utf8;
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
        confess [1009, 'The Temple can only view nearby planets.'];
    }
    unless ($building->body->calculate_distance_to_target($planet) < $building->effective_level * 1000) {
        confess [1009, 'That planet is too far away.'];
    }
    
    my @map;
    my @buildings = @{$planet->building_cache};
    foreach my $building (@buildings) {
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
    my ($self, $session_id, $building_id, $star_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $star;
    if ($star_id) {
        $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($star_id);
        unless (defined $star) {
            confess [1002, 'Could not find that star.'];
        }
    }
    else {
        $star = $building->body->star;
    }
    unless ($building->body->calculate_distance_to_target($star) < $building->effective_level * 1000) {
        confess [1009, 'That star is too far away.'];
    }    
    my @planets;
    my $bodies = $star->bodies;
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

