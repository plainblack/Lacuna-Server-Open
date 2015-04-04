package Lacuna::Role::Ship::Arrive::DumpWaste;

use strict;
use Moose::Role;
use Lacuna::Util qw(commify);

my %is_scow_type = map { $_ => 1 } qw(scow scow_fast scow_large scow_mega);

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');

    # we're dumping on a star, nothing to do but go home
    if ($self->foreign_star_id) {
      $self->payload({ resources => { waste => 0 } });
      $self->update;
      return;
    }

    # dump it!
    my $body_attacked = $self->foreign_body;
#If a scow crashes into an unclaimed planet, does anyone hear?
    unless ($body_attacked->empire) {
      return if ($self->type eq "attack_group");
      $self->delete;
      confess [-1];
    }
    my $payload = $self->payload;
    my $waste_dumped = 0;
    $body_attacked->recalc_stats;
    if (defined($payload->{resources})) {
      $waste_dumped = $payload->{resources}{waste} if defined($payload->{resources}{waste});
    }
    return unless $waste_dumped > 0;
    $body_attacked->add_waste($waste_dumped);
    $body_attacked->needs_recalc(1);
    $body_attacked->needs_surface_refresh(1);
    $body_attacked->update;
    $waste_dumped = commify($waste_dumped); # commify so emails look nicer

    # all pow
    my $done_after = 1;
    my $number_of_scows = 0;
    if ($self->type eq "attack_group") {
        my @trim;
        for my $key ( keys %{$payload->{fleet}}) {
            if ($is_scow_type{$payload->{fleet}->{$key}->{type}}) {
                push @trim, $key;
                $number_of_scows += $payload->{fleet}->{$key}->{quantity};
            }
            else {
                $done_after = 0;
            }
        }
#reset payload if needed
        unless ($done_after) {
            for my $key (@trim) {
                delete $payload->{fleet}->{$key};
            }
            $self->number_of_docks($self->number_of_docks - $number_of_scows);
            $self->payload($payload);
            $self->update;
        }
    }
    else {
        $number_of_scows = 1;
    }

    my $good_grammar = $number_of_scows > 1 ? "s" : "";

    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'our_scow_hit.txt',
            params      => [$good_grammar, $body_attacked->x, $body_attacked->y, $body_attacked->name, $waste_dumped],
        );
    }

    unless ($body_attacked->empire->skip_attack_messages) {
        $body_attacked->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'hit_by_scow.txt',
            params      => [$self->body->empire_id, $self->body->empire->name, $good_grammar, $body_attacked->id, $body_attacked->name, $waste_dumped],
        );
    }

    $body_attacked->add_news(30, '%s is so polluted that waste seems to be falling from the sky.', $body_attacked->name);

    my $logs = Lacuna->db->resultset('Lacuna::DB::Result::Log::Battles');
    $logs->new({
        date_stamp => DateTime->now,
        attacking_empire_id     => $self->body->empire_id,
        attacking_empire_name   => $self->body->empire->name,
        attacking_body_id       => $self->body_id,
        attacking_body_name     => $self->body->name,
        attacking_unit_name     => "Scows",
        attacking_type          => $self->type_formatted,
        attacking_number        => $number_of_scows,
        defending_empire_id     => $body_attacked->empire_id,
        defending_empire_name   => $body_attacked->empire->name,
        defending_body_id       => $body_attacked->id,
        defending_body_name     => $body_attacked->name,
        defending_unit_name     => '',
        defending_type          => '',
        defending_type          => 0,
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

after send => sub {
    my ($self, %options ) = @_;
    my $waste_sent;

    if ($self->type eq "attack_group") {
        my $payload = $self->payload;
        my $hold_size = $self->hold_size;
        my $room;
        if ($payload->{resources}->{waste}) {
            $room = $hold_size - $payload->{resources}->{waste};
        }
        else {
            $payload->{resources}->{waste} = 0;
            $room = $hold_size;
        }
        return if $room < 1;
        if ($self->body->waste_stored < $room) {
          $waste_sent = $self->body->waste_stored > 0 ? $self->body->waste_stored : 0;
        }
        else {
          $waste_sent = $room;
        }
        $payload->{resources}->{waste} += $waste_sent;
        $self->payload($payload);
    }
    else {
        if ($self->body->waste_stored < $self->hold_size) {
          $waste_sent = $self->body->waste_stored > 0 ? $self->body->waste_stored : 0;
        }
        else {
          $waste_sent = $self->hold_size;
        }
        $self->payload({ resources => { waste => $waste_sent }});
    }
    $self->body->spend_waste($waste_sent)->update;
    $self->update;
};

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1013, 'Can only be sent to inhabited planets.'] if ($target->isa('Lacuna::DB::Result::Map::Body::Planet') && !$target->empire_id);
    confess [1011, 'You have no waste to ship' ] unless ($self->body->waste_stored > 0);
#    confess [1011, 'You do not have enough waste to fill this scow. You need '.$self->hold_size.' waste to launch.'] unless ($self->body->waste_stored > $self->hold_size);
};

1;
