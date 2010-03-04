package Lacuna::Building::PlanetaryCommand;

use Moose;
extends 'Lacuna::Building';
use Lacuna::Constants qw(ORE_TYPES);

sub app_url {
    return '/planetarycommand';
}

sub model_class {
    return 'Lacuna::DB::Building::PlanetaryCommand';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $building = $self->get_building($building_id);
    my $empire = $self->get_empire_by_session($session_id);
    my $out = $orig->($self, $empire, $building);
    my $body = $building->body;
    my %ore;
    foreach my $type (ORE_TYPES) {
        $ore{$type} = $body->$type();
    }
    $out->{planet} = {
        ore             => \%ore,
        water           => $body->water,
        building_count  => $body->building_count,
        size            => $body->size,
        orbit           => $body->orbit,
        x               => $body->x,
        y               => $body->y,
        z               => $body->z,
        star_id         => $body->star_id,
        name            => $body->name,
        image           => $body->image,
        id              => $body->id,
    };
    return $out;
};

no Moose;
__PACKAGE__->meta->make_immutable;

