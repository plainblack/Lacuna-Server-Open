package Lacuna::RPC::Firebase;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use WWW::Firebase::TokenGenerator;

sub get_token {
    my ($self, $session_id) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $firebase_secret = Lacuna->config->get('firebase/secret');
    unless ($firebase_secret) {
        return { token => '', status => $self->format_status($empire)};
    }
    my $token_generator = WWW::Firebase::TokenGenerator->new({
        secret  => $firebase_secret,
        admin   => $empire->is_admin,
        debug   => Lacuna->config->get('firebase/debug'),
    });
    
    my $token = $token_generator->create_token({
        empire_id       => $empire->id,
        empire_name     => $empire->name,
        alliance_id     => $empire->alliance_id,
        alliance_name   => $empire->alliance_id ? $empire->alliance->name : '',
    });

    return { token => $token, status => $self->format_status($empire)};
}

__PACKAGE__->register_rpc_method_names(
    qw(get_token),
);

no Moose;
__PACKAGE__->meta->make_immutable;

