package Lacuna::RPC::Captcha;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Lacuna::Util qw(format_date randint);
use DateTime;

sub fetch {
    my ($self, $session_id) = @_;
    my $captcha = Lacuna->db->resultset('Lacuna::DB::Result::Captcha')->find(randint(1,Lacuna->config->get('captcha/total')||65664));
    Lacuna->cache->set('captcha', $session_id, { guid => $captcha->guid, solution => $captcha->solution }, 60 * 30 );
	Lacuna->cache->delete('captcha_valid', $session_id);
    return {
        guid    => $captcha->guid,
        url     => $captcha->uri,
    };
}

sub solve {
    my ($self, $session_id, $guid, $solution) = @_;
    if (defined $guid && defined $solution) {                                               # offered a solution
        my $captcha = Lacuna->cache->get_and_deserialize('captcha', $session_id);
        if (ref $captcha eq 'HASH') {                                                       # a captcha has been set
            if ($captcha->{guid} eq $guid) {                                                # the guid is the one set
                if ($captcha->{solution} eq $solution) {                                    # the solution is correct
					Lacuna->cache->set('captcha_valid', $session_id, 1, 60 * 30 );
                    return 1;
                }
            }
        }
    }
    confess [1014, 'Captcha not valid.', $self->fetch($session_id)];
}

__PACKAGE__->register_rpc_method_names(
    { name => "fetch", },
	{ name => "solve", },
);


no Moose;
__PACKAGE__->meta->make_immutable;


1;
