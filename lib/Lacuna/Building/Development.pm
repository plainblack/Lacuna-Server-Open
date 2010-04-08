package Lacuna::Building::Development;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/development';
}

sub model_class {
    return 'Lacuna::DB::Building::Development';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_domain, $building_id);
    my $out = $orig->($self, $empire, $building);
    $out->{build_queue} = $building->format_build_queue;
    return $out;
};

sub subsidize_build_queue {
    my ($self, $session_id, $building_id, $amount) = @_;
    if ($amount < 0) {
        confess [1009, "You can't subsidize that little.", $amount];
    }
    my $empire = $self->get_empire_by_session($session_id);
    if ($empire->essentia < $amount) {
        confess [1011, "You don't have enough essentia."];
    }
    my $building = $empire->get_building($self->model_class, $building_id);
    $building->subsidize_build_queue($amount);
    return {
        build_queue => $building->format_build_queue,
        status      => $empire->get_status,
    };
}

__PACKAGE__->register_rpc_method_names(qw(subsidize_build_queue));


no Moose;
__PACKAGE__->meta->make_immutable;

