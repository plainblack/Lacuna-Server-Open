package Lacuna::Building::Observatory;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/observatory';
}

sub model_class {
    return 'Lacuna::DB::Building::Observatory';
}

sub abandon_probe {
    my ($self, $session_id, $building_id, $star_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $star = $self->simpledb->domain('star')->find($star_id);
    unless (defined $star) {
        confess [ 1002, 'Star does not exist.', $star_id];
    }
    my $bodies = $star->bodies(where => { class => ['like', 'Lacuna::DB::Body::Planet%'] });
    while (my $body = $bodies->next) {
        if ($empire->id eq $body->empire_id) {
            confess [ 1010, "You can't remove a probe from a system you inhabit.", $body->id ];
        }
    }
    $self->simpledb->domain('probes')->search( where => {
        empire_id   => $empire->id,
        star_id     => $star->id,
    })->delete;
    $empire->clear_probed_stars;
    return {status => $empire->get_status};
}

sub get_probed_stars {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my @stars;
    $page_number ||= 1;
    my $probes = $self->simpledb->search( where => { empire_id => $empire->id })->paginate(25, $page_number);
    while (my $probe = $probes->next) {
        push @stars, $probe->star->get_status($empire);
    }
    return {
        stars   => \@stars,
        status  => $empire->get_status
        };
}

__PACKAGE__->register_rpc_method_names(qw(get_probed_stars abandon_probe));


no Moose;
__PACKAGE__->meta->make_immutable;

