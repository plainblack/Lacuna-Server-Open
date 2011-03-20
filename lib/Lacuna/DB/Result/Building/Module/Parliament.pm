package Lacuna::DB::Result::Building::Module::Parliament;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Module';

use constant controller_class => 'Lacuna::RPC::Building::Parliament';
use constant image => 'parliament';
use constant name => 'Parliament';
use constant max_instances_per_planet => 1;

sub propositions {
    my ($self) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->search({station_id => $self->body->id});
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
