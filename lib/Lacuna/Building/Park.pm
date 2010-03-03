package Lacuna::Building::Park;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/park';
}

sub model_class {
    return 'Lacuna::DB::Building::Park';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $building = $self->get_building($building_id);
    my $empire = $self->get_empire_by_session($session_id);
    $building->check_party_over;
    my $out = $orig->($self, $empire, $building);
    if ($building->party_in_progress) {
        $out->{party}{seconds_remaining} = $building->party_seconds_remaining;
    }
    else {
        $out->{party}{can_throw} = eval { $building->can_throw_a_party } ? 1 : 0;
    }
    return $out;
};

sub throw_a_party {
    my ($self, $session_id, $building_id) = @_;
    my $building = $self->get_building($building_id);
    my $empire = $self->get_empire_by_session($session_id);
    if ($building->empire_id ne $empire->id) {
        confess [1010, "Can't throw a party at a park you don't own.", $building_id];
    }
    $building->throw_a_party;
    return $self->view($empire, $building);
}

__PACKAGE__->register_rpc_method_names(qw(throw_a_party build));


no Moose;
__PACKAGE__->meta->make_immutable;

