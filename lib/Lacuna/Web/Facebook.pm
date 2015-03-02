package Lacuna::Web::Facebook;

use Moose;
use utf8;
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

    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({facebook_uid => $user->{id} })->first;
    my $uri = Lacuna->config->get('server_url');
    if (defined $empire && $empire->stage eq 'founded') {
        $empire->facebook_token($fb->access_token);
        $empire->update;
        $uri .= '#session_id=%s';
        $uri = sprintf $uri, $empire->start_session({ api_key => 'facebook' })->id;
    }
    elsif (defined $empire && $empire->stage ne 'founded') {
        $empire->facebook_token($fb->access_token);
        $empire->update;
        $uri .= '#empire_id=%s';
        $uri = sprintf $uri, $empire->id;
    }
    else {
        $uri .= '#facebook_uid=%s&facebook_token=%s&facebook_name=%s';
        $uri = sprintf $uri, $user->{id}, $fb->access_token, $user->{name};
    }
    return [$uri, { status => 302 } ];
}

sub www_authorize {
    my ($self, $request) = @_;
    return [$self->facebook->authorize->extend_permissions(qw(offline_access))->uri_as_string, { status => 302 }];
}

sub www_server_list {
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

sub www_default {
    my ($self, $request) = @_;
    my $config = Lacuna->config;
    my $fb = Facebook::Graph->new(
            postback    => $config->get('server_url').'facebook/my/empire',
            app_id      => $config->get('facebook/app_id'),
            secret      => $config->get('facebook/secret'),
        );
    return [$fb->authorize->extend_permissions(qw(publish_stream offline_access))->uri_as_string, { status => 302 }];
}

sub www_my_empire {
    my ($self, $request) = @_;
    my $config = Lacuna->config;
    my $fb = Facebook::Graph->new(
            postback    => $config->get('server_url').'facebook/my/empire',
            app_id      => $config->get('facebook/app_id'),
            secret      => $config->get('facebook/secret'),
        );
    $fb->request_access_token($request->param('code'));
    my $user = $fb->query->find('me')->request->as_hashref;
    unless (exists $user->{id}) {
        return $self->format_error(q{The bad thing that should never happen just happened. Facebook doesn't remember who you are!});   
    }

    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({facebook_uid => $user->{id} })->first;
    my $out;
    unless (defined $empire) {
        $out = q{<p><a href="}.$config->get('server_url').q{" target="_new">Join thousands of other players online now in this strategic browser game.</a> No downloads required. Play for free.</p>
            <p>The Expanse is a region of space with millions of habitable worlds. You can play with or compete against thousands of
            other players as you build your empire, fight off spies in a battle for cold war supremacy, form alliances, search the
            expanse for lost ancient artifacts, and more.</p>};
        return $self->wrapper($out, { title => 'Play for Free in The Lacuna Expanse' });   
    }
    $out .= '<div style="float: right; border: 3px solid white; font-size: 20pt; background-image: url(https://s3.amazonaws.com/www.lacunaexpanse.com/button_bkg.png)"><a href="'.$config->get('server_url').'" target="_new"></a></div>';
    $out .= '<h1>'.$empire->name.'</h1>';
    my $planets = $empire->planets;
    while (my $planet = $planets->next) {
        $out .= '<div style="float: left; height: 250px; text-align: center;"><img src="https://d16cbq0l6kkf21.cloudfront.net/assets/star_system/'.$planet->image_name.'.png'.'" alt="planet">
            <br>'.$planet->name.'</div>';
    }
    $out .= '<div style="clear: both;"></div>';
    return $self->wrapper($out, { title => 'My Empire in The Lacuna Expanse', logo => 1 });
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

