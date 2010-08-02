package Lacuna::Web::Facebook;

use Moose;
no warnings qw(uninitialized);
extends qw(Lacuna::Web);
use Facebook::Graph;
use LWP::UserAgent;

has facebook => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $config = Lacuna->config;
        return Facebook::Graph->new(
            postback    => $config->get('server_url').'facebook/postback',
            app_id      => $config->get('facebook/app_id'),
            secret      => $config->get('facebook/secret'),
        );
    },
);

sub www_postback {
    my ($self, $request) = @_;
    my $fb = $self->facebook;
    $fb->request_access_token($request->param('code'));
    my $user = $fb->query->find('me')->request->as_hashref;

    unless (exists $user->{id}) {
        return $self->format_error('Could not authenticate your Facebook account. Please close this window and try again.');   
    }

    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({facebook_uid => $user->{id} }, { rows => 1 })->single;
    my $uri = Lacuna->config->get('server_url');
    if (defined $empire) {
        $empire->facebook_token($fb->access_token);
        $empire->update;
        $uri .= '?session_id=%s';
        $uri = sprintf $uri, $empire->start_session('facebook')->id;
    }
    else {
        $uri .= '?facebook_uid=%s&facebook_token=%s';
        $uri = sprintf $uri, $user->{id}, $fb->access_token;
    }
    return [$uri, { status => 302 } ];
}

sub www_authorize {
    my ($self, $request) = @_;
    return [$self->facebook->authorize->extend_permissions(qw(email publish_stream offline_access))->uri_as_string, { status => 302 }];
}

sub www_default {
    my ($self, $request) = @_;
    my $cache = Lacuna->cache;
    my $servers = $cache->get_and_deserialize('www.lacunaexpanse.com', 'servers.json');
    unless (defined $servers && ref $servers eq 'ARRAY') {
        my $servers_json = LWP::UserAgent->new->get('http://www.lacunaexpanse.com/servers.json')->content;
        $servers = JSON->new->decode($servers_json);
        $cache->set('www.lacunaexpanse.com', 'servers.json', $servers, 60 * 60 * 24);
    }
    my $template = '<a href="%s" class="server_button" target="_blank">
<div class="server_name_label">Server</div>
<div class="server_name">%s</div>
<div class="location_label">Location</div>
<div class="location">%s</div>
<div class="status_label">Status</div>
<div class="status">%s</div>
<div class="play_now">Play Now!</div>
</a>
';
    my $out = '<img src="https://s3.amazonaws.com/www.lacunaexpanse.com/logo.png" style="margin-left: 50px;">
<div style="font-size: 50px; margin-left: 140px; font-family: Helvetica; color: white;">Choose A Server</div>';
    foreach my $server (@{$servers}) {
        $out .= sprintf $template, $server->{uri}.'facebook/authorize', $server->{name}, $server->{location}, $server->{status};
    }
    return $self->wrapper($out, { title => 'Available Servers' });
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

