package Lacuna::RPC::Building::Park;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/park';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Park';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $out = $orig->($self, $empire, $building);
    if ($building->is_working) {
        $out->{party} = {
            seconds_remaining   => $building->work_seconds_remaining,
            happiness           => $building->work->{happiness_from_party},
        };
    }
    else {
        $out->{party}{can_throw} = (eval { $building->can_throw_a_party }) ? 1 : 0;
    }
    return $out;
};

sub throw_a_party {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->throw_a_party;
    return $self->view($empire, $building);
}

__PACKAGE__->register_rpc_method_names(qw(throw_a_party build));


no Moose;
__PACKAGE__->meta->make_immutable;

