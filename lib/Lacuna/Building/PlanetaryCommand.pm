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
    my $building = $empire->get_building($self->model_class, $building_id);
    my $out = $orig->($self, $empire, $building);
    $out->{planet} = $building->body->get_status($empire);
    return $out;
};

sub view_freebies {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $free_stuff = $building->body->freebies;
    my %freebies;
    foreach my $class (keys %{$free_stuff}) {
        $freebies{$class->name} = $free_stuff->{$class};
    }
    return {
        freebies    => \%freebies,
        status      => $empire->get_status,
    };
}

__PACKAGE__->register_rpc_method_names(qw(view_freebies));


no Moose;
__PACKAGE__->meta->make_immutable;

