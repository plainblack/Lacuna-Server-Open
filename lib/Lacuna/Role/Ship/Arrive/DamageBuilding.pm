package Lacuna::Role::Ship::Arrive::DamageBuilding;

use strict;
use Moose::Role;
use Lacuna::Util qw(randint);
use DateTime;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');

#Check if attack group
# If groups of snarks
#   check if reasonable to assume zero out everything on planet (depends on type, etc...)
#   if not, go thru an attack for each.
# else return and go to next step
# 1) Group of snarks?
# 2) How many target buildings?
# 3) See if reasonable that buildings get zeroed?
    my %snarks = {
        snarks => {
            count => 0,
            target => [],
        },
        observatory_seeker => {
            count => 0,
            target => [],
        },
        spaceport_seeker => {
            count => 0,
            target => [],
        },
        security_ministry_seeker => {
            count => 0,
            target => [],
        },
    };
    if ($self->type eq "attack_group") {
        my $payload = $self->payload;
        for my $fleet (keys %{$payload->{fleet}}) {
            if ($payload->{fleet}->{$fleet}->{type} eq "snark") {
                $snarks{snarks}->{count} += $payload->{fleet}->{$fleet}->{quantity};
            }
            elsif ($payload->{fleet}->{$fleet}->{type} eq "snark2") {
                $snarks{snarks}->{count} += 4 * $payload->{fleet}->{$fleet}->{quantity};
            }
            elsif ($payload->{fleet}->{$fleet}->{type} eq "snark3") {
                $snarks{snarks}->{count} += 9 * $payload->{fleet}->{$fleet}->{quantity};
            }
            elsif ($payload->{fleet}->{$fleet}->{type} eq "observatory_seeker") {
                $snarks{observatory_seeker}->{count} += $payload->{fleet}->{$fleet}->{quantity};
                $snarks{observatory_seeker}->{target} = $payload->{fleet}->{$fleet}->{target_building};
            }
            elsif ($payload->{fleet}->{$fleet}->{type} eq "security_ministry_seeker") {
                $snarks{security_ministry_seeker}->{count} += $payload->{fleet}->{$fleet}->{quantity};
                $snarks{security_ministry_seeker}->{target} = $payload->{fleet}->{$fleet}->{target_building};
            }
            elsif ($payload->{fleet}->{$fleet}->{type} eq "spaceport_seeker") {
                $snarks{spaceport_seeker}->{count} += $payload->{fleet}->{$fleet}->{quantity};
                $snarks{spaceport_seeker}->{target} = $payload->{fleet}->{$fleet}->{target_building};
            }
        }
    }
    else {
        my $type = $self->type;
        if ($type eq "snark") {
            $snarks{snarks}->{count} = 1;
        }
        elsif ($type eq "snark2") {
            $snarks{snarks}->{count} = 4;
        }
        elsif ($type eq "snark3") {
            $snarks{snarks}->{count} = 9;
        }
        elsif ($type eq "observatory_seeker") {
            $snarks{observatory_seeker}->{count} = 1;
            $snarks{observatory_seeker}->{target} = $self->target_building;
        }
        elsif ($type eq "security_ministry_seeker") {
            $snarks{security_ministry_seeker}->{count} = 1;
            $snarks{security_ministry_seeker}->{target} = $self->target_building;
        }
        elsif ($type eq "spaceport_seeker") {
            $snarks{spaceport_seeker}->{count} = 1;
            $snarks{spaceport_seeker}->{target} = $self->target_building;
        }
    }
    my $body_attacked = $self->foreign_body;
    my @all_builds =
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

    if ( $snarks{snarks}->{count}/4 > scalar @all_builds) {
#More than capable of zeroing all buildings
        for my $building (@all_builds) {
            $building->spend_efficiency(100)->update;
        }
#Deal with email and log results
    }
    else {
        my $building;
        for my $sn_type ("observatory_seeker", "security_ministry_seeker",
                      "spaceport_seeker", "snark_count") {
            my @tbuilds;
            if ($snarks{$sn_type}->{count}) {
                for my $tb ( @{$snarks{$sn_type}->{target}}) {
                    my @temp = $body_attacked->get_buildings_of_class($tb);
                    if (@temp) {
                      push @tbuilds, @temp;
                    }
                }
            }
            else {
                @tbuilds = @all_builds;
            }
            if ($snarks{$sn_type}->{count}/4 > scalar @tbuilds) {
                for $building (@tbuilds) {
                    $building->spend_efficiency(100)->update;
#Deal with email and log results
                }
            }
            else {
                my $count = 0;
                for (0..$snarks{$sn_type}->{count}) {
                    my $amount = randint(10,70);
                    ($building) = 
                        sort {
                            $b->efficiency <=> $a->efficiency ||
                            rand() <=> rand()
                        }
                        grep {
                            ($_->efficiency > 0)
                        } @tbuilds;
                    if ($building) {
                        $building->spend_efficiency($amount)->update;
#Deal with email and log results
                    }
                }
            }
        }
    }

    
#Send email, n19 and battle log
    # let everyone know what's going on
    my $building_name = "Trash";
    unless ($body_attacked->empire->skip_attack_messages) {
        $body_attacked->empire->send_predefined_message(
        tags        => ['Attack','Alert'],
        filename    => 'ship_hit_building.txt',
        params      => [$self->type_formatted, $building_name, $body_attacked->id,
                        $body_attacked->name, $self->body->empire_id, $self->body->empire->name],
            );
    }
    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'our_ship_hit_building.txt',
            params      => [$self->type_formatted, $body_attacked->x, $body_attacked->y,
                            $body_attacked->name, $building_name, 100],
            );
    }
    $body_attacked->add_news(70, sprintf('An attack ship screamed out of the sky and damaged the %s on %s.',$building_name, $body_attacked->name));

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
        defending_unit_name     => sprintf("%s (%d,%d)", $building_name, 0, 0),
        defending_type          => $building_name,
        attacked_empire_id      => $body_attacked->empire_id,
        attacked_empire_name    => $body_attacked->empire->name,
        attacked_body_id        => $body_attacked->id,
        attacked_body_name      => $body_attacked->name,
        victory_to              => 'attacker',
    });

    $log->insert;
    if ($self->type ne "attack_group") {
        $self->delete;
        confess [-1];
    }
};

1;
