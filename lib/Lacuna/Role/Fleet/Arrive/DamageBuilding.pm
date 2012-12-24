package Lacuna::Role::Fleet::Arrive::DamageBuilding;

use strict;
use Moose::Role;
use Lacuna::Util qw(randint);
use DateTime;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');

    # determine damage
    my $amount = randint(10,70);
    
    # determine target building
    my $building;
    my $body_attacked = $self->foreign_body;
    my ($citadel) = grep {$_->class eq 'Lacuna::DB::Result::Building::Permanent::CitadelOfKnope'} @{$body_attacked->building_cache};
    if (defined $citadel) {
        $building = $citadel;
    }
    if ($self->target_building) {
        for my $tb ( @{$self->target_building} ) {
            $building ||= $body_attacked->get_building_of_class($tb);
        }
    }
    if (not defined $building) {
        ($building) =
            sort {
                $b->efficiency <=> $a->efficiency ||
                rand() <=> rand()
            }
            grep {
                ($_->class ne 'Lacuna::DB::Result::Building::Permanent::Crater') and
                ($_->class ne 'Lacuna::DB::Result::Building::DeployedBleeder') and
                ($_->class ne 'Lacuna::DB::Result::Building::TheDillonForge')
            } @{$body_attacked->building_cache};
    }
    return if not defined $building;
    
    # let everyone know what's going on
    unless ($body_attacked->empire->skip_attack_messages) {
        $body_attacked->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'ship_hit_building.txt',
            params      => [$self->type_formatted, $building->name, $body_attacked->id, $body_attacked->name, $self->body->empire_id, $self->body->empire->name],
        );
    }
    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'our_ship_hit_building.txt',
            params      => [$self->type_formatted, $body_attacked->x, $body_attacked->y, $body_attacked->name, $building->name, $amount],
        );
    }
    $body_attacked->add_news(70, sprintf('An attack fleet screamed out of the sky and damaged the %s on %s.',$building->name, $body_attacked->name));

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
        defending_unit_name     => sprintf("%s (%d,%d)", $building->name, $building->x, $building->y),
        defending_type          => $building->name,
        attacked_empire_id      => $body_attacked->empire_id,
        attacked_empire_name    => $body_attacked->empire->name,
        attacked_body_id        => $body_attacked->id,
        attacked_body_name      => $body_attacked->name,
        victory_to              => 'attacker',
    })->insert;

    # handle citadel damage
    if (defined $citadel) {
        if ($citadel->level < 2) {
            $citadel->delete;
            $self->delete;
        }
        else {
            $citadel->level($citadel->level - 1);
            $citadel->update;
            if ($citadel->efficiency) {
                $self->body_id($body_attacked->id);
                $self->direction('in');
                $self->land;
                $self->update;
            }
            else {
                $self->delete;
            }
        }
        $body_attacked->needs_surface_refresh(1);
        $body_attacked->update;
    }
    
    # handle regular building damage
    else {
        $building->spend_efficiency($amount)->update;
        if ($self->splash_radius) {
            foreach my $i (1..$self->splash_radius) {
                $amount /= $i + 1;
                my @splashed = 
                    grep {
                        ($_->x > $building->x - $i) and
                        ($_->x < $building->x + $i) and
                        ($_->y > $building->y - $i) and
                        ($_->y < $building->y + $i) and
                        ($_->class ne 'Lacuna::DB::Result::Building::Permanent::Crater') and
                        ($_->class ne 'Lacuna::DB::Result::Building::DeployedBleeder') and
                        ($_->class ne 'Lacuna::DB::Result::Building::TheDillonForge')
                    } @{$body_attacked->building_cache};
                foreach my $damaged (@splashed) {
                    $damaged->body($body_attacked);
                    $damaged->spend_efficiency($amount)->update;
                }
            }
        }
        $self->delete;
    }
    confess [-1];
};

1;
