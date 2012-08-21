package Lacuna::RPC::Alliance;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Lacuna::Util qw(format_date randint);
use DateTime;
use String::Random qw(random_string);
use UUID::Tiny ':std';
use Time::HiRes;

sub find {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            name            => shift,
        };
    }
    my $name = $args->{name};

    unless (length($name) >= 3) {
        confess [1009, 'Alliance name too short. Your search must be at least 3 characters.'];
    }
    my $empire = $self->get_empire_by_session($args->{session_id});
    my $alliances = Lacuna->db->resultset('Alliance')->search({name => {'like' => $name.'%'}}, {rows=>100});
    my @list_of_alliances;
    my $limit = 100;
    while (my $alliance = $alliances->next) {
        push @list_of_alliances, {
            id      => $alliance->id,
            name    => $alliance->name,
        };
        $limit--;
        last unless $limit;
    }
    return { alliances => \@list_of_alliances, status => $self->format_status($session) };
}


sub view_profile {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            alliance_id     => shift,
        };
    }

    my $alliance_id = $args->{alliance_id};
    my $empire = $self->get_empire_by_session($args->{session_id});
    unless (defined $alliance_id && length $alliance_id) {
        confess [1002, "You must specify an alliance ID."];
    }
    my $alliance = Lacuna->db->resultset('Lacuna::DB::Result::Alliance')->find($alliance_id);
    my $members = $alliance->members;
    my @members_list;
    while (my $member = $members->next) {
        push @members_list, {
            id          => $member->id,
            name        => $member->name,
        };
    }
    my $stations = $alliance->stations;
    my @stations_list;
    my $influence = 0;
    while (my $station = $stations->next) {
        push @stations_list, {
            id          => $station->id,
            name        => $station->name,
            x           => $station->x,
            y           => $station->y,
        };
        $influence += $station->total_influence;
    }
    my %out = (
        id              => $alliance->id,
        name            => $alliance->name,
        description     => $alliance->description,
        date_created    => $alliance->date_created_formatted,
        leader_id       => $alliance->leader_id,
        members         => \@members_list,
        space_stations  => \@stations_list,
        influence       => $influence,
    );
    return { profile => \%out, status => $self->format_status($session) };
}


__PACKAGE__->register_rpc_method_names(qw(
    find
    view_profile
));

no Moose;
__PACKAGE__->meta->make_immutable;

