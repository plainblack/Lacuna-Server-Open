package Lacuna::Web::Chat;

use Moose;
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
    my $content = '
           <!-- Envolve -->
           <script type="text/javascript">envoSn='.Lacuna->config->get('envolve/Sn').'</script>
           <script type="text/javascript" src="http://d.envolve.com/env.nocache.js"></script>
           <input type="hidden" id="EnvolveDesiredFirstName" value="'.$empire->name.'">
    ';
    return $self->wrapper($content, { 
        title       => 'Lacuna Expanse Chat', 
        head_tags   => '<meta name="viewport" content="height=device-height, width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">', 
        logo        => 1 
    });
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

