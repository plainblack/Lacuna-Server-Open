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
    $out->{subsidy_cost} = $building->calculate_subsidy;
    return $out;
};

sub subsidize_build_queue {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $building->is_offline;
    my $subsidy = $building->calculate_subsidy;
    if ($empire->essentia < $subsidy) {
        confess [1011, "You don't have enough essentia."];
    }
    $empire->spend_essentia($subsidy);
    $empire->trigger_full_update(skip_put=>1);
    $empire->put;
    $building->subsidize_build_queue;
    return {
        status          => $empire->get_status,
        essentia_spent  => $subsidy,
    };
}

__PACKAGE__->register_rpc_method_names(qw(subsidize_build_queue));


no Moose;
__PACKAGE__->meta->make_immutable;

