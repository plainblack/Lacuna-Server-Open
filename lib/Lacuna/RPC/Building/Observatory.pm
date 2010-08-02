package Lacuna::RPC::Building::Observatory;

use Moose;
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
    Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search(
        {
            empire_id   => $empire->id,
            star_id     => $star->id,
        })->delete;
    $empire->clear_probed_stars;
    return {status => $self->format_status($empire, $building->body)};
}

sub get_probed_stars {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @stars;
    $page_number ||= 1;
    my $probes = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search(
        { body_id => $building->body_id },
        { rows => 25, page => $page_number }
    );
    while (my $probe = $probes->next) {
        push @stars, $probe->star->get_status($empire);
    }
    return {
        stars   => \@stars,
        star_count => $probes->pager->total_entries,
        status  => $self->format_status($empire, $building->body),
        };
}

__PACKAGE__->register_rpc_method_names(qw(get_probed_stars abandon_probe));


no Moose;
__PACKAGE__->meta->make_immutable;

