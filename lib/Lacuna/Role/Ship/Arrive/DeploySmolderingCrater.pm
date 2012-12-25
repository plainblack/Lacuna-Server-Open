package Lacuna::Role::Ship::Arrive::DeploySmolderingCrater;

use strict;
use Moose::Role;
use Lacuna::Util qw(randint);

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    # deploy the crater
    my $body_attacked = $self->foreign_body;
    my ($x, $y) = eval{$body_attacked->find_free_space};
    unless ($@) {
        my $deployed = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
            class       => 'Lacuna::DB::Result::Building::Permanent::Crater',
            x           => $x,
            y           => $y,
        });
        $body_attacked->build_building($deployed, 1);
        $deployed->start_work({},3600 * randint(24,168))->update;
        $body_attacked->needs_surface_refresh(1);
        $body_attacked->update;
    }
    
    # notify home
    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'thud_hit_target.txt',
            params      => [$body_attacked->x, $body_attacked->y, $body_attacked->name],
        );
    }

    # notify attacked
    unless ($body_attacked->empire_id && $body_attacked->empire->skip_attack_messages) {
        $body_attacked->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'thud_hit_us.txt',
            params      => [$self->body->empire->id, $self->body->empire->name, $body_attacked->id, $body_attacked->name],
        );
    }
    $body_attacked->add_news(70, sprintf("A quake measuring %.1f on the seismic magnitude scale just struck %s.",rand(10), $body_attacked->name));
    
    my $logs = Lacuna->db->resultset('Lacuna::DB::Result::Log::Battles');
    $logs->new({
        date_stamp => DateTime->now,
        attacking_empire_id     => $self->body->empire_id,
        attacking_empire_name   => $self->body->empire->name,
        attacking_body_id       => $self->body_id,
        attacking_body_name     => $self->body->name,
        attacking_unit_name     => $self->name,
        attacking_type          => $self->type_formatted,
        defending_empire_id     => $body_attacked->empire_id,
        defending_empire_name   => $body_attacked->empire->name,
        defending_body_id       => $body_attacked->id,
        defending_body_name     => $body_attacked->name,
        defending_unit_name     => '',
        defending_type          => '',
        attacked_empire_id      => $body_attacked->empire_id,
        attacked_empire_name    => $body_attacked->empire->name,
        attacked_body_id        => $body_attacked->id,
        attacked_body_name      => $body_attacked->name,
        victory_to              => 'attacker',
    })->insert;

    # all pow
    $self->delete;
    confess [-1];
};


1;
