package Lacuna::Building::PlanetaryCommand;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/planetarycommand';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::PlanetaryCommand';
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
    while (my $freebie = $free_stuff->next) {
        my $level = $freebie->level;
        if ($freebie->extra_build_level) {
            $level .= ' ('.$freebie->extra_build_level.')';
        }
        $freebies{$freebie->class->name} = $level;
    }
    return {
        freebies    => \%freebies,
        status      => $empire->get_status,
    };
}

__PACKAGE__->register_rpc_method_names(qw(view_freebies));


no Moose;
__PACKAGE__->meta->make_immutable;

