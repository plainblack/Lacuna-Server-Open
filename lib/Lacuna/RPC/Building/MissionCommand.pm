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

sub missions {
    my ($self) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Mission')->search({
        zone                    => $self->body->zone,
    },{
        order_by   => 'date_posted',
    });
}



no Moose;
__PACKAGE__->meta->make_immutable;

