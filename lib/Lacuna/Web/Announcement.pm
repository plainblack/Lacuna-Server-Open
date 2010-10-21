package Lacuna::Web::Announcement;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends qw(Lacuna::Web);

sub www_default {
    my ($self, $request) = @_;
    my $session = $self->get_session($request->param('session_id'));
    unless (defined $session) {
        confess [ 401, 'You must be logged in to get the announcement.'];
    }
    my $empire = $session->empire;
    unless (defined $empire) {
        confess [401, 'Empire not found.'];
    }
    my $cache = Lacuna->cache;
    my $alert = $cache->get('announcement','alert');
    $cache->set('announcement'.$alert,$empire->id, 1, 60 * 60 * 24);
    return $self->wrapper($cache->get('announcement','message'), { 
        title       => 'Lacuna Expanse Server Announcement', 
        head_tags   => '<meta name="viewport" content="height=device-height, width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes">', 
    });
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

