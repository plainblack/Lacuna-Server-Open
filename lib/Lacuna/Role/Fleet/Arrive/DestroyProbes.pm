package Lacuna::Role::Fleet::Arrive::DestroyProbes;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');

    # not a star
    return unless $self->foreign_star_id;

    # find probes to destroy
    my $probes = Lacuna->db->resultset('Probes')->search({star_id => $self->foreign_star_id });
    my $count;

    my $logs = Lacuna->db->resultset('Log::Battles');
    # destroy those suckers
    while (my $probe = $probes->next) {

        unless ($probe->empire->skip_attack_messages) {
            $probe->empire->send_predefined_message(
                tags        => ['Attack','Alert'],
                filename    => 'probe_detonated.txt',
                params      => [$probe->body->id, $probe->body->name, $self->foreign_star->x, $self->foreign_star->y, $self->foreign_star->name, $self->body->empire_id, $self->body->empire->name],
            );
        }

# Battle Log for now is not added for probe destruction.
# Should we allow probe source empires be returned or not?
#        $logs->new({
#            date_stamp => DateTime->now,
#            attacking_empire_id     => $self->body->empire_id,
#            attacking_empire_name   => $self->body->empire->name,
#            attacking_body_id       => $self->body_id,
#            attacking_body_name     => $self->body->name,
#            attacking_unit_name     => $self->name,
#            attacking_type          => $self->type_formatted,
#            defending_empire_id     => $probe->empire_id,
#            defending_empire_name   => $probe->empire->name,
#            defending_body_id       => $probe->body->id,
#            defending_body_name     => $probe->body->name,
#            defending_unit_name     => sprintf("Probe {Starmap %s %s %s}",
#                                         $self->foreign_star->x, $self->foreign_star->y,
#                                         $self->foreign_star->name),
#            defending_type          => 'Probe',
#            attacked_empire_id      => $probe->empire_id,
#            attacked_empire_name    => $probe->empire->name,
#            attacked_body_id        => $probe->body->id,
#            attacked_body_name      => $probe->body->name,
#            victory_to              => 'attacker',
#        })->insert;
        $count++;
        $probe->delete;
    }
    
    # notify about destruction
    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'detonator_destroyed_probes.txt',
            params      => [$count, $self->foreign_star->x, $self->foreign_star->y, $self->foreign_star->name],
        );
    }
    
    # it's all over but the cryin
    $self->delete;
    confess [-1];
};

1;
