package Lacuna::Building::PlanetaryCommand;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/planetarycommand';
}

sub model_class {
    return 'Lacuna::DB::Building::PlanetaryCommand';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_domain, $building_id);
    my $out = $orig->($self, $empire, $building);
    $out->{planet} = $building->body->get_extended_status;
    return $out;
};

no Moose;
__PACKAGE__->meta->make_immutable;

