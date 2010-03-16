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
    while (my $body = $star) {
        if ($empire->id eq $body->empire_id) {
            confess [ 1010, "You can't remove a probe from a system you inhabit.", $body->id ];
        }
    }
    my @new;
    foreach my $id (@{$empire->probed_stars}) {
        next if $id eq $star_id;
        push @new, $id;
    }
    $empire->probed_stars(\@new);
    $empire->put;
    return {status => $empire->get_status};
}

sub get_probed_stars {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my @stars;
    $page_number ||= 1;
    my $end = $page_number * 25;
    my $start = $end - 24;
    my $count = 0;
    foreach my $star_id (sort @{$empire->probed_stars}) {
        $count++;
        next if ($start < $count);
        my $star = $self->simpledb->domain('star')->find($star_id);
        push @stars, $star->get_status($empire);
        last if ($count >= $end);
    }
    return {
        stars   => \@stars,
        status  => $empire->get_status
        };
}

__PACKAGE__->register_rpc_method_names(qw(get_probed_stars abandon_probe));


no Moose;
__PACKAGE__->meta->make_immutable;

