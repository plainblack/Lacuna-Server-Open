package Lacuna::Role::Ship::Arrive::DestroyProbes;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');

    # find probes to destroy
    my $probes = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({star_id => $self->foreign_star_id });
    my $count;
    
    # destroy those suckers
    while (my $probe = $probes->next) {
        $probe->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'probe_detonated.txt',
            params      => [$self->foreign_star->x, $self->foreign_star->y, $self->foreign_star->name, $self->body->empire_id, $self->body->empire->name],
        );
        $count++;
        $probe->delete;
    }
    
    # notify about destruction
    $self->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'detonator_destroyed_probes.txt',
        params      => [$count, $self->foreign_star->x, $self->foreign_star->y, $self->foreign_star->name],
    );
    
    # it's all over but the cryin
    $self->delete;
    confess [-1];
};

1;
