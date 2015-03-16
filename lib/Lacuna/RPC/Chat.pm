package Lacuna::RPC::Chat;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Firebase::Auth;
use Firebase;
use Gravatar::URL;
use Ouch;

sub init_chat {
    my ($self, $session_id) = @_;

    my $empire = $self->get_empire_by_session($session_id);

    my $config = Lacuna->config;
    my $firebase_config = $config->get('firebase');
    return undef unless $firebase_config;
    return undef if $empire->current_session->is_sitter && $empire->id > 1;
    my $chat_auth = Firebase::Auth->new(
        secret  => $firebase_config->{auth}{secret},
#        debug   => \1,
        data    => {
            uid          => $empire->id,
            isModerator => $empire->chat_admin ? \1 : \0,
            isStaff => $empire->is_admin ? \1 : \0,
        }
     #   data   => $data,
    );
    my $firebase = Firebase->new(
        firebase    => $firebase_config->{firebase},
        authobj     => $chat_auth,
    );
    my $chat_name = $empire->name;
    my $aname;
    $chat_name =~ s/[^0-9a-zA-Z_ ]/_/g;
    $chat_name =~ s/__*/_/g;
    if ($empire->alliance_id) {
        $aname = $empire->alliance->name;
        $aname =~ s/[^0-9a-zA-Z_ ]/_/g;
        $aname =~ s/__*/_/g;
        $chat_name .= " (".$aname.")";
    }
    if (0) {
#    if ($empire->alliance_id) {
    	my $room = eval { $firebase->get('room-metadata/'.$empire->alliance_id) };
        if ($@) {
  	     warn bleep;
        }
        elsif (defined $room) {
            eval {
            	$firebase->patch('room-metadata/'.$empire->alliance_id.'/authorizedUsers', {
                	$empire->id => \1
           	    });
	        };
            if ($@) {
                warn bleep;
            }
        }
        else {
            eval { 
	            $firebase->put('room-metadata/'.$empire->alliance_id, {
        	        id              => $empire->alliance_id,
                	name            => $aname,
	                type            => 'private',
        	        createdByUserId => $empire->id,
                	'.priority'     => {'.sv' => 'timestamp'},
	                authorizedUsers => {$empire->id => \1},
        	    });
	        };
	        if ($@) {
		        warn bleep;
	        }
        }
        $firebase->put('users/'.$empire->id.'/rooms/'.$empire->alliance_id, {
            id      => $empire->alliance_id,
            active  => \1, 
            name    => $aname,
        });
    }
#    if ($empire->is_admin) {
#        $chat_name .= " <ADMIN>";
#    }
#    elsif ($empire->chat_admin) {
#        $chat_name .= " <MOD>";
#    }
    my $gravatar_id = gravatar_id($empire->email);
    my $gravatar_url = gravatar_url(
        email   => $empire->email,
        default => 'monsterid',
	size    => 300,
        https   => 1,
	);
    my $ret = {
        status          => $self->format_status($empire),
        gravatar_url    => $gravatar_url,
        chat_name       => $chat_name,
        chat_auth       => $chat_auth->create_token,
        isStaff         => $empire->is_admin   ? \1 : \0,
        isModerator     => $empire->chat_admin ? \1 : \0,
    };
    if (0) {
#    if ($empire->alliance_id) {
        $ret->{private_room} = {
            id          => $empire->alliance_id,
            name        => $aname,
        };
    }
    return $ret;
}    

__PACKAGE__->register_rpc_method_names(
    qw(init_chat),
);


no Moose;
__PACKAGE__->meta->make_immutable;

