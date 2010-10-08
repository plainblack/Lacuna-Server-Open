package Lacuna::RPC::Alliance;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Lacuna::Util qw(format_date randint);
use DateTime;
use String::Random qw(random_string);
use UUID::Tiny ':std';
use Time::HiRes;

sub find {
    my ($self, $session_id, $name) = @_;
    unless (length($name) >= 3) {
        confess [1009, 'Alliance name too short. Your search must be at least 3 characters.'];
    }
    my $empire = $self->get_empire_by_session($session_id);
    my $alliances = Lacuna->db->resultset('Lacuna::DB::Result::Alliance')->search({name => {'like' => $name.'%'}}, {rows=>100});
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
    return { alliances => \@list_of_alliances, status => $self->format_status($empire) };
}



sub view_profile {
    my ($self, $session_id, $alliance_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $alliance = Lacuna->db->resultset('Lacuna::DB::Result::Alliance')->find($alliance_id);
    unless (defined $alliance) {
        confess [1002, 'The alliance you wish to view does not exist.', $alliance_id];
    }
    my $members = $alliance->members;
    my @members_list;
    while (my $member = $members->next) {
        push @members_list, {
            id          => $member->id,
            name        => $member->name,
        };
    }
    my %out = (
        id              => $alliance->id,
        name            => $alliance->name,
        description     => $alliance->description,
        date_created    => $alliance->date_created_formatted,
        leader_id       => $alliance->leader_id,
        members         => \@members_list,
        space_stations  => [],
        influence       => 0,
    );
    return { profile => \%out, status => $self->format_status($empire) };
}


__PACKAGE__->register_rpc_method_names(
    qw(find view_profile),
);


no Moose;
__PACKAGE__->meta->make_immutable;

