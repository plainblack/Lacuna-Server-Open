package Lacuna::Building::WasteRecycling;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/wasterecycling';
}

sub model_class {
    return 'Lacuna::DB::Building::Waste::Recycling';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $building->check_recycling_over;
    my $out = $orig->($self, $empire, $building);
    if ($building->recycling_in_progress) {
        $out->{recycle}{seconds_remaining} = $building->recycling_seconds_remaining;
    }
    else {
        $out->{recycle}{can} = (eval { $building->can_recycle }) ? 1 : 0;
    }
    return $out;
};

sub recycle {
    my ($self, $session_id, $building_id, $water, $ore, $energy, $use_essentia) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $body = $building->body;
    $body->tick;
    
    # building could be  stale
    $building = $empire->get_building($self->model_class, $building_id);
    $building->body($body);
    
    $building->recycle($water, $ore, $energy, $use_essentia);
    return {
        seconds_remaining   => $building->recycling_seconds_remaining,
        status              => $empire->get_status,
    };    
}

__PACKAGE__->register_rpc_method_names(qw(recycle));

no Moose;
__PACKAGE__->meta->make_immutable;

