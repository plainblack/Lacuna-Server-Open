package Lacuna::Role::Ship::Arrive::DeploySupplyPod;

use strict;
use Moose::Role;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);

requires 'supply_pod_level';

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    # deploy the pod
    my $body = $self->foreign_body;
    my ($x, $y) = eval{$body->find_free_space};
    if ($@) {   
        # notify home of lost ship 
        $self->body->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'no_space_for_ship.txt',
            params      => [$self->type, $body->x, $body->y, $body->name, " a mid-air collision"],
        );
    
        $body->add_news(10 ,"Humanitarian mission bound for %s lost during final entry", $body->name);
    
    }    
    else {
        my $deployed = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
            class       => 'Lacuna::DB::Result::Building::SupplyPod',
            x           => $x,
            y           => $y,
            level       => $self->supply_pod_level - 1,
        });
        $body->build_building($deployed, 1);
        $deployed->finish_upgrade;
        $body->recalc_stats;
        my $payload = $self->payload;
        if (exists $payload->{resources}) {
            my %resources = %{$payload->{resources}};
            foreach my $type (keys %resources) {
                $body->add_type($type, $resources{$type});
            }
        }
        $body->update;

        # all pow
        $self->delete;
        confess [-1];
    }
};

1;
