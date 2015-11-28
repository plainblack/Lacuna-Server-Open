package Lacuna::Web::EntertainmentVote;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends qw(Lacuna::Web);
use Lacuna::Util qw(randint);

sub www_default {
    my ($self, $request) = @_;
    my $session = $self->get_session($request->param('session_id'));
    unless (defined $session) {
        confess [ 401, 'You must be logged in to vote.'];
    }
    my $empire = $session->empire;
    unless (defined $empire) {
        confess [401, 'Empire not found.'];
    }
    if ($session->is_sitter) {
        confess [1015, 'Sitters cannot enter the lottery.'];
    }
    my $url = $request->param('site_url');
    unless (defined $url) {
        confess [417, 'You need to specify a site.'];
    }
    my $found;
    my $building_id = $request->param('building_id');
    unless ($building_id) {
        confess [400, 'You need to pass a building id'];
    }
    my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->find($building_id);
    unless (defined $building) {
        confess [404, 'Could not find your entertainment district.'];
    }
    unless ($building->body->empire_id == $empire->id) {
        confess [401, 'You do not own that building.'];
    }
    foreach my $site (@{Lacuna->config->get('voting_sites')}) {
        if ($site->{url} eq $url) {
            $found = 1;
            last;
        }
    }
    unless ($found) {
        confess [404, 'You specified an invalid site.'];
    }
    my $cache = Lacuna->cache;
    $cache->set($url,$empire->id,1, 60*60*24);
    my $ticket = randint(1,99999);
    my $ymd = DateTime->now->ymd;
    my $zone = $building->body->zone;
    if ($ticket > $cache->get('high_vote'.$zone, $ymd)) {
        $cache->set('high_vote'.$zone, $ymd, $ticket, 60*60*48);
        $cache->set('high_vote_empire'.$zone, $ymd, $empire->id, 60*60*48);
    }
    Lacuna->db->resultset('Lacuna::DB::Result::Log::Lottery')->new({
        empire_id   => $empire->id,
        empire_name => $empire->name,
        ip_address  => $request->address,
        api_key     => $empire->current_session->api_key,
        url         => $url,
    })->insert;
    return [$url, { status => 302 }];

}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

