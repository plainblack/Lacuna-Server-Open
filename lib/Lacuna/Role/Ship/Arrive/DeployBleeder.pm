package Lacuna::Role::Ship::Arrive::DeployBleeder;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    my $bleed_num = 0;
    my $done_after = 1;
    if ($self->type eq "attack_group") {
        my $payload = $self->payload;
        my @trim;
        for my $fleet (keys %{$payload->{fleet}}) {
            if ($payload->{fleet}->{$fleet}->{type} eq "bleeder") {
                $bleed_num += $payload->{fleet}->{$fleet}->{quantity};
                push @trim, $fleet;
            }  
        }
        for my $key (@trim) {
            delete $payload->{fleet}->{$key};
        }
        if (keys %{$payload->{fleet}}) {
            $self->payload($payload);
            $done_after = 0;
        }
    }
    else {
        $bleed_num = 1;
    }
    # deploy the bleeders
    my $body_attacked = $self->foreign_body;
    my $deployed = 0;
    for $deployed (1..$bleed_num) {
        my $body_attacked = $self->foreign_body;
        my ($x, $y) = eval{$body_attacked->find_free_space};
        if ($@) {
            $deployed--;
            last;
        }
        else {
            my $deployed = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
                class       => 'Lacuna::DB::Result::Building::DeployedBleeder',
                x           => $x,
                y           => $y,
            });
            $body_attacked->build_building($deployed, 1);
            $deployed->finish_upgrade;
            $body_attacked->needs_surface_refresh(1);
            $body_attacked->update;
        }
    }
    
    # notify home
    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'bleeder_deployed.txt',
            params      => [
                            $deployed,
                            $bleed_num,
                            $body_attacked->x,
                            $body_attacked->y,
                            $body_attacked->name],
            );
    }

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

    if ($done_after) {
        $self->delete;
        confess [-1];
    }
};


1;
