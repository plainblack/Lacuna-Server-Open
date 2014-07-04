package Lacuna::RPC::Building::Observatory;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/observatory';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Observatory';
}

sub abandon_probe {
    my ($self, $session_id, $building_id, $star_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($star_id);
    unless (defined $star) {
        confess [ 1002, 'Star does not exist.', $star_id];
    }
    my $probe = $building->probes->search(
        {
            star_id => $star->id,
        },
        {rows => 1}
    )->single;
    if (defined $probe) {
        $probe->delete;
    }
    $empire->clear_probed_stars;
    return {status => $self->format_status($empire, $building->body)};
}

sub abandon_all_probes {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->probes->delete;
    $empire->clear_probed_stars;
    return {status => $self->format_status($empire, $building->body)};
}

sub get_probed_stars {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @stars;
    $page_number ||= 1;
    my $probes = $building->probes->search(undef,{ rows => 30, page => $page_number });
    while (my $probe = $probes->next) {
        push @stars, $probe->star->get_status($empire);
    }
    my $travelling = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ body_id => $building->body_id, type=>'probe', task=>'Travelling' })->count;
    return {
        stars       => \@stars,
        star_count  => $probes->pager->total_entries,
        status      => $self->format_status($empire, $building->body),
        max_probes  => $building->max_probes,
        travelling  => $travelling,
    };
}

__PACKAGE__->register_rpc_method_names(qw(get_probed_stars abandon_probe abandon_all_probes));


no Moose;
__PACKAGE__->meta->make_immutable;

