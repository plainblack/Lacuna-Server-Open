package Lacuna::RPC::Captcha;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Lacuna::Util qw(format_date randint);
use DateTime;

sub fetch {
    my ($self, $plack_request) = @_;
    my $ip = $plack_request->address;
    my $captcha = Lacuna->db->resultset('Lacuna::DB::Result::Captcha')->find(randint(1,65664));
    Lacuna->cache->set('captcha', $ip, { guid => $captcha->guid, solution => $captcha->solution }, 60 * 30 );
    return {
        guid    => $captcha->guid,
        url     => $captcha->uri,
    };
}

sub solve {
    my ($self, $plack_request, $session_id, $guid, $solution) = @_;
    my $ip = $plack_request->address;
    if (defined $guid && defined $solution) {                                               # offered a solution
        my $captcha = Lacuna->cache->get_and_deserialize('captcha', $ip);
        if (ref $captcha eq 'HASH') {                                                       # a captcha has been set
            if ($captcha->{guid} eq $guid) {                                                # the guid is the one set
                if ($captcha->{solution} eq $solution) {                                    # the solution is correct
                    my $empire = $self->get_empire_by_session($session_id);
                    $empire->current_session->valid_captcha(1);
                    return 1;
                }
            }
        }
    }
    confess [1014, 'Captcha not valid.', $self->fetch($plack_request)];
}

__PACKAGE__->register_rpc_method_names(
    { name => "fetch", options => { with_plack_request => 1 } },
	{ name => "solve", options => { with_plack_request => 1 } },
);


no Moose;
__PACKAGE__->meta->make_immutable;


1;
