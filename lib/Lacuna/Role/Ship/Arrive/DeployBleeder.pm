package Lacuna::Role::Ship::Arrive::DeployBleeder;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    # deploy the bleeder
    my $body_attacked = $self->foreign_body;
    my ($x, $y) = $body_attacked->find_free_space;
    my $deployed = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        class       => 'Lacuna::DB::Result::Building::DeployedBleeder',
        x           => $x,
        y           => $y,
    });
    $body_attacked->build_building($deployed);
    
    # notify home
    $self->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'bleeder_deployed.txt',
        params      => [$body_attacked->x, $body_attacked->y, $body_attacked->name],
    );
    
    # all pow
    $self->delete;
    confess [-1];
};


1;
