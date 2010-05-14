package Lacuna::Stats;

use Moose;
extends 'JSON::RPC::Dispatcher::App';

with 'Lacuna::Role::Sessionable';

sub server {
        my ($self, $session_id) = @_;
        my $empire = $self->get_empire_by_session($session_id);
}

sub credits {
    return [
            { 'Game Design'         => ['JT Smith','Jamie Vrbsky']},
            { 'Web Client'          => ['John Rozeske']},
            { 'iPhone Client'       => ['Kevin Runde']},
            { 'Game Server'         => ['JT Smith']},
            { 'Art and Icons'       => ['Ryan Knope','JT Smith','Joseph Wain / glyphish.com','Keegan Runde']},
            { 'Geology Consultant'  => ['Geofuels, LLC / geofuelsllc.com']},
            { 'Playtesters'         => ['John Oettinger','Jamie Vrbsky','Mike Kastern','Chris Burr','Eric Patterson','Frank Dillon','Kristi McCombs','Ryan McCombs','Mike Helfman','Tavis Parker','Sarah Bownds']},
            { 'Game Support'        => ['Plain Black Corporation / plainblack.com']},
            ];
}



__PACKAGE__->register_rpc_method_names(qw(credits));

no Moose;
__PACKAGE__->meta->make_immutable;

