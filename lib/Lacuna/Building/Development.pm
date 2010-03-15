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
    my $body = $building->body;
    my $builds = $body->builds;
    my @queue;
    while (my $build = $builds->next) {
        my $target = $build->building;
        push @queue, {
            build_queue_id      => $build->id,
            building_id         => $target->id,
            name                => $target->name,
            to_level            => ($target->level + 1),
            seconds_remaining   => $build->seconds_remaining,
        };
    }
    $out->{build_queue} = \@queue;
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
    my $building = $empire->get_building($self->model_domain, $building_id);
    $building->subsidize_build_queue($amount);
    return $self->view($empire, $building);
}

no Moose;
__PACKAGE__->meta->make_immutable;

