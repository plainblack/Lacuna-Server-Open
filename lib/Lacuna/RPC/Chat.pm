package Lacuna::RPC::Chat;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Chat::Envolve;


sub get_commands {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $chat = Chat::Envolve->new(
        api_key     => Lacuna->config->get('envolve/api_key'),
        client_ip   => 'none',
    );
    my %params;
    if ($empire->alliance_id) {
        my $alliance = $empire->alliance;
        if (defined $alliance) {
            $params{last_name} = '('.$alliance->name.')';
        }
    }
    if ($empire->is_admin) {
        $params{is_admin} = 1;
    }
    my $login = $chat->get_login_command($empire->name, %params);
    my $logout = $chat->get_logout_command;
    return { login_command => $login, logout_command => $logout, status => $self->format_status($empire) };
}


__PACKAGE__->register_rpc_method_names(
    qw(find view_profile),
);


no Moose;
__PACKAGE__->meta->make_immutable;

