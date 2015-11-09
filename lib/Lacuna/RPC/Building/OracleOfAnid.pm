package Lacuna::RPC::Building::OracleOfAnid;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/oracleofanid';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::OracleOfAnid';
}

sub get_star {
    my ($self, $session_id, $building_id, $star_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($star_id);
    unless (defined $star) {
        confess [1002, "Couldn't find a star."];
    }
    unless ($building->body->calculate_distance_to_target($star) < $building->range) {
        confess [1009, 'That star is too far away.'];
    }
    return { star=>$star->get_status($empire, 1), status=>$self->format_status($empire, $building->body) };
}

sub get_probed_stars {
    my ($self, $args) = @_;

    my $page_number = $args->{page_number} || 1;
    my $page_size   = $args->{page_size} || 25;

    if ($page_size > 200) {
        confess [1002, "Page size cannot exceed 200."];
    }

    my $session  = $self->get_session({session_id => $args->{session_id}, building_id => $args->{building_id} });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;

    my @stars;
    my $probes = $building->probes->search(undef,{ rows => $page_size, page => $page_number });
    while (my $probe = $probes->next) {
        push @stars, $probe->star->get_status($empire);
    }
    return {
        stars           => \@stars,
        star_count      => $probes->pager->total_entries,
        status          => $self->format_status($empire, $building->body),
        max_distance    => $building->level * 10,
    };
}

__PACKAGE__->register_rpc_method_names(qw(
    get_star
    get_probed_stars
));


no Moose;
__PACKAGE__->meta->make_immutable;

