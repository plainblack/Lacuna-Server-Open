package Lacuna::DB::Result::Building::Module::StationCommand;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Module';

use constant controller_class => 'Lacuna::RPC::Building::StationCommand';
use constant image => 'stationcommand';
use constant name => 'Station Command Center';
use constant max_instances_per_planet => 1;
use constant food_consumption   =>  90;
use constant ore_consumption    =>  90;
use constant water_consumption  => 110;
use constant energy_consumption => 110;

before 'can_demolish' => sub {
   confess [1010, 'You cannot demolish the Station Command Center. Use the abandon station function if you no longer want this station.'];
};

sub incoming_supply_chains {
    my ($self) = @_;

    return Lacuna->db->resultset('Lacuna::DB::Result::SupplyChain')->search({ target_id => $self->body_id });
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
