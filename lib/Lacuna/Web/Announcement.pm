package Lacuna::Web::Announcement;

use Moose;
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
    $cache->set('announcement',$empire->id, 1, 60 * 60 * 24) unless ($cache->get('announcement',$empire->id));
    return [ $cache->get('announcement','message'), { status => 200 }];
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

