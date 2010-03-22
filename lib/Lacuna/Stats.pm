package Lacuna::Stats;

use Moose;
extends 'JSON::RPC::Dispatcher::App';

has simpledb => (
    is      => 'ro',
    required=> 1,
);

with 'Lacuna::Role::Sessionable';

sub server {
        my ($self, $session_id) = @_;
        my $empire = $self->get_empire_by_session($session_id);
}

sub credits {
    return [
            { 'Game Design'         => ['JT Smith']},
            { 'Web Client'          => ['John Rozeske']},
            { 'iPhone Client'       => ['Kevin Runde']},
            { 'Game Server'         => ['JT Smith']},
            { 'Art and Icons'       => ['Ryan Knope','JT Smith','Joseph Wain']},
            { 'Geology Consultant'  => ['Geo Fuels, LLC']},
            { 'Playtesters'         => ['John Oettinger','Jamie Vrbsky']},
            { 'Game Support'        => ['Plain Black Corporation']},
            ];
}



__PACKAGE__->register_rpc_method_names(qw(credits));

no Moose;
__PACKAGE__->meta->make_immutable;

