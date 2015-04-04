package Lacuna::Role::Ship::Arrive::DeploySmolderingCrater;

use strict;
use Moose::Role;
use Lacuna::Util qw(randint);

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    my $thud_num = 0;
    my $done_after = 1;
    if ($self->type eq "attack_group") {
        my $payload = $self->payload;
        my @trim;
        for my $fleet (keys %{$payload->{fleet}}) {
            if ($payload->{fleet}->{$fleet}->{type} eq "thud") {
                $thud_num += $payload->{fleet}->{$fleet}->{quantity};
                push @trim, $fleet;
            }  
            else {
                $done_after = 0;
            }
        }
        if ($done_after == 0 and $thud_num > 0) {
            for my $key (@trim) {
                delete $payload->{fleet}->{$key};
            }
            $self->payload($payload);
            $self->update;
        }
    }
    else {
        $thud_num = 1;
    }
    return if $thud_num < 1;

    # deploy the craters
    my $body_attacked = $self->foreign_body;
    my $craters = 0;
    for (1..$thud_num) {
        my ($x, $y) = eval{$body_attacked->find_free_space};
        if ($@) {
            last;
        }
        else {
            my $deployed = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
                class       => 'Lacuna::DB::Result::Building::Permanent::Crater',
                x           => $x,
                y           => $y,
            });
            $body_attacked->build_building($deployed, 1);
            $deployed->start_work({},3600 * randint(24,168))->update;
            $craters++;
        }
    }
    $body_attacked->needs_recalc(1);
    $body_attacked->needs_surface_refresh(1);
    $body_attacked->update;
    
    # notify home
    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'thud_hit_target.txt',
            params      => [
                            $craters,
                            $thud_num,
                            $body_attacked->x,
                            $body_attacked->y,
                            $body_attacked->name],
        );
    }

    # notify attacked
    if ($craters > 0 and $body_attacked->empire_id && !$body_attacked->empire->skip_attack_messages) {
        $body_attacked->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'thud_hit_us.txt',
            params      => [$self->body->empire->id, $self->body->empire->name, $body_attacked->id, $body_attacked->name],
        );
    }
    $body_attacked->add_news(70, "A quake measuring %.1f on the seismic magnitude scale just struck %s.",rand(10), $body_attacked->name);

    my $logs = Lacuna->db->resultset('Lacuna::DB::Result::Log::Battles');
    $logs->new({
        date_stamp => DateTime->now,
        attacking_empire_id     => $self->body->empire_id,
        attacking_empire_name   => $self->body->empire->name,
        attacking_body_id       => $self->body_id,
        attacking_body_name     => $self->body->name,
        attacking_unit_name     => "Thuds",
        attacking_type          => $self->type_formatted,
        attacking_number        => $craters,
        defending_empire_id     => defined($body_attacked->empire) ? $body_attacked->empire_id : 0,
        defending_empire_name   => defined($body_attacked->empire) ? $body_attacked->empire->name : "",
        defending_body_id       => $body_attacked->id,
        defending_body_name     => $body_attacked->name,
        defending_unit_name     => '',
        defending_type          => '',
        attacked_empire_id      => defined($body_attacked->empire) ? $body_attacked->empire_id : 0,
        attacked_empire_name    => defined($body_attacked->empire) ? $body_attacked->empire->name : "",
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
