package Lacuna::Web::Chat;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends qw(Lacuna::Web);

sub www_default {
    my ($self, $request) = @_;
    my $session = $self->get_session($request->param('session_id'));
    unless (defined $session) {
        confess [ 401, 'You must be logged in to use chat.'];
    }
    my $empire = $session->empire;
    unless (defined $empire) {
        confess [401, 'Empire not found.'];
    }
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
    return $self->wrapper($chat->get_tags($empire->name, %params), { 
        title       => 'Lacuna Expanse Chat', 
        head_tags   => '<meta name="viewport" content="height=device-height, width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">', 
        logo        => 1 
    });
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

