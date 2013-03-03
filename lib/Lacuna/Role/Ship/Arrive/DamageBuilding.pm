package Lacuna::Role::Ship::Arrive::DamageBuilding;

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
    my ($citadel) = grep {
            $_->class eq 'Lacuna::DB::Result::Building::Permanent::CitadelOfKnope'
        and $_->efficiency == 100
        and $_->is_working == 0
        and $_->level > 0
        and $_->is_building == 0
    } @{$body_attacked->building_cache};

    if (defined $citadel) {
        $building = $citadel;
    }
    elsif (scalar @{$self->target_building} > 0) {
        my @builds;
        for my $tb ( @{$self->target_building} ) {
            my @temp = $body_attacked->get_buildings_of_class($tb);
            if (@temp) {
              push @builds, @temp;
            }
        }
        ($building) = 
            sort {
                $b->efficiency <=> $a->efficiency ||
                rand() <=> rand()
            }
            grep {
                ($_->efficiency > 0)
            } @builds;
    }
    else {
        ($building) =
            sort {
                $b->efficiency <=> $a->efficiency ||
                rand() <=> rand()
            }
            grep {
                ($_->efficiency > 0) and
                ($_->class ne 'Lacuna::DB::Result::Building::Permanent::Crater') and
                ($_->class ne 'Lacuna::DB::Result::Building::DeployedBleeder') and
                ($_->class ne 'Lacuna::DB::Result::Building::TheDillonForge') and
                ($_->class ne 'Lacuna::DB::Result::Building::Permanent::CitadelOfKnope')
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
    $body_attacked->add_news(70, sprintf('An attack ship screamed out of the sky and damaged the %s on %s.',$building->name, $body_attacked->name));

    my $log = Lacuna->db->resultset('Log::Battles')->new({
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
    });

    if (defined $citadel) {
        # handle citadel defence
        #
        $log->victory_to('defender');
        
        $citadel->start_work({}, 900 / $citadel->level);

        # Repel the ship at quarter speed
        $self->turn_around(int($self->speed / 4));
    }
    else {
        # Handle regular building damage
        #
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
                        ($_->class ne 'Lacuna::DB::Result::Building::TheDillonForge') and
                        ($_->class ne 'Lacuna::DB::Result::Building::Permanent::CitadelOfKnope')
                    } @{$body_attacked->building_cache};
                foreach my $damaged (@splashed) {
                    $damaged->body($body_attacked);
                    $damaged->spend_efficiency($amount)->update;
                }
            }
        }
        $self->delete;
    }
    $log->insert;
    confess [-1];
};

1;
