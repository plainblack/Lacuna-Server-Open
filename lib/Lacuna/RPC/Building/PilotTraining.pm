package Lacuna::RPC::Building::PilotTraining;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/pilottraining';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::PilotTraining';
}

no Moose;
__PACKAGE__->meta->make_immutable;

