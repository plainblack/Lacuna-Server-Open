package Lacuna::RPC::Building::MissionCommand;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/missioncommand';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::MissionCommand';
}

no Moose;
__PACKAGE__->meta->make_immutable;

