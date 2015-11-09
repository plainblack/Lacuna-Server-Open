package Lacuna::RPC::Building::DeployedBleeder;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/deployedbleeder';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::DeployedBleeder';
}

around demolish => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    $session->check_captcha;
    return $orig->($self, $session, $building_id);
};

no Moose;
__PACKAGE__->meta->make_immutable;

