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
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($star_id);
    unless (defined $star) {
        confess [1002, "Couldn't find a star."];
    }
    unless ($building->body->calculate_distance_to_target($star) < $building->level * 1000) {
        confess [1009, 'That star is too far away.'];
    }
    return { star=>$star->get_status($empire, 1), status=>$self->format_status($empire, $building->body) };
}

__PACKAGE__->register_rpc_method_names(qw(get_star));


no Moose;
__PACKAGE__->meta->make_immutable;

