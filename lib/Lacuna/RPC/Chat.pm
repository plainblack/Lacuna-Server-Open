package Lacuna::RPC::Chat;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Firebase::Auth;
use Firebase;
use Gravatar::URL;

sub init_chat {
    my ($self, $session_id) = @_;

    my $empire = $self->get_empire_by_session($session_id);

    my $config = Lacuna->config;
    my $firebase_config = $config->get('firebase');
    my $chat_auth = Firebase::Auth->new(
        secret  => $firebase_config->{auth}{secret},
        data    => {
            id          => $empire->id,
            chat_admin  => $empire->chat_admin ? \1 : \0,
        }
     #   data   => $data,
    )->create_token;
    my $firebase = Firebase->new(%{$firebase_config});

#    if (0) {
    if ($empire->alliance_id) {
    	my $room = $firebase->get('room-metadata/'.$empire->alliance_id);
        if (defined $room) {
            $firebase->patch('room-metadata/'.$empire->alliance_id.'/authorizedUsers', {
                $empire->id => \1
            });
        }
        else {
            $firebase->put('room-metadata/'.$empire->alliance_id, {
                id              => $empire->alliance_id,
                name            => $empire->alliance->name,
                type            => 'private',
                createdByUserId => $empire->id,
                '.priority'     => {'.sv' => 'timestamp'},
                authorizedUsers => {$empire->id => \1},
            });
        }
    }
    my $gravatar_id = gravatar_id($empire->email);
    my $gravatar_url = gravatar_url(
        email   => $empire->email,
        default => 'monsterid',
        size    => 300,
    );
    my $ret = {
        status          => $self->format_status($empire),
        gravatar_url    => $gravatar_url,
        chat_auth       => $chat_auth,
    };
#    if (0) {
    if ($empire->alliance_id) {
        $ret->{private_room} = {
            id          => $empire->alliance_id,
            name        => $empire->alliance->name,
        };
    }
    return $ret;
}    

__PACKAGE__->register_rpc_method_names(
    qw(init_chat),
);


no Moose;
__PACKAGE__->meta->make_immutable;

