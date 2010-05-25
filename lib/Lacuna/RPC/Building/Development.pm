package Lacuna::RPC::Building::Development;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/development';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Development';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $out = $orig->($self, $empire, $building);
    $out->{build_queue} = $building->format_build_queue;
    $out->{subsidy_cost} = $building->calculate_subsidy;
    return $out;
};

sub subsidize_build_queue {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $subsidy = $building->calculate_subsidy;
    if ($empire->essentia < $subsidy) {
        confess [1011, "You don't have enough essentia."];
    }
    $empire->spend_essentia($subsidy, 'construction subsidy');
    $empire->update;
    $building->subsidize_build_queue;
    return {
        status          => $self->format_status($empire, $building->body),
        essentia_spent  => $subsidy,
    };
}

__PACKAGE__->register_rpc_method_names(qw(subsidize_build_queue));


no Moose;
__PACKAGE__->meta->make_immutable;

