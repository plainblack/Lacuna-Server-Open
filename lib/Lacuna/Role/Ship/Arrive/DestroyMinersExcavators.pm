package Lacuna::Role::Ship::Arrive::DestroyMinersExcavators;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
  my ($self) = @_;

  # we're coming home
  return if ($self->direction eq 'in');

  my $body_attacked = $self->foreign_body;
  my $is_asteroid   = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Asteroid');
  my $is_uninhabit  = ($body_attacked->isa('Lacuna::DB::Result::Map::Body::Planet') and !(defined($body_attacked->empire_id)) );
# not an asteroid or uninhabited planet
  return unless ( $self->foreign_body_id && ($is_asteroid || $is_uninhabit));
  my $do_boom = 0;
  my $done_after = 1;
  if ($self->type eq "attack_group") {
      my $payload = $self->payload;
      my @trim;
      for my $fleet (keys %{$payload->{fleet}}) {
          if ($payload->{fleet}->{$fleet}->{type} eq "detonators") {
              $do_boom = 1;
              push @trim, $fleet;
          }
          else {
              $done_after = 0;
          }
      }
      if ($done_after == 0 and $do_boom) {
          for my $key (@trim) {
              delete $payload->{fleet}->{$key};
          }
          $self->payload($payload);
          $self->update;
      }
  }
  else {
      $do_boom = 1;
  }
  return unless $do_boom;

  my $logs = Lacuna->db->resultset('Lacuna::DB::Result::Log::Battles');
  my $mcount = 0;
  my $ecount = 0;
# find mining platforms to destroy
  if ($is_asteroid) {
    my $platforms = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->search({asteroid_id => $self->foreign_body_id });
# destroy those suckers
    while (my $platform = $platforms->next) {
      my $empire = $platform->planet->empire;

      unless ($empire->skip_attack_messages) {
        $empire->send_predefined_message(
           tags        => ['Attack','Alert'],
           filename    => 'mining_platform_destroyed.txt',
           params      => [$body_attacked->x, $body_attacked->y, $body_attacked->name, $self->body->empire_id, $self->body->empire->name],
        );
      }

      $logs->new({
        date_stamp => DateTime->now,
        attacking_empire_id     => $self->body->empire_id,
        attacking_empire_name   => $self->body->empire->name,
        attacking_body_id       => $self->body_id,
        attacking_body_name     => $self->body->name,
        attacking_unit_name     => $self->name,
        attacking_type          => $self->type_formatted,
        attacking_number        => 1,
        defending_empire_id     => $empire->id,
        defending_empire_name   => $empire->name,
        defending_body_id       => $body_attacked->id,
        defending_body_name     => $body_attacked->name,
        defending_unit_name     => 'Mining Platform',
        defending_type          => 'Mining Platform',
        defending_number        => 1,
        attacked_empire_id      => $empire->id,
        attacked_empire_name    => $empire->name,
        attacked_body_id        => $body_attacked->id,
        attacked_body_name      => $body_attacked->name,
        victory_to              => 'attacker',
      })->insert;
      $mcount++;
      $platform->delete;
    }
  }
# Destroy Excavs
  my $excavs = Lacuna->db->resultset('Lacuna::DB::Result::Excavators')->search({body_id => $self->foreign_body_id });
  while (my $excav = $excavs->next) {
    my $empire = $excav->planet->empire;

    unless ($empire->skip_attack_messages) {
      $empire->send_predefined_message(
         tags        => ['Attack','Alert'],
         filename    => 'excavator_destroyed.txt',
         params      => [$body_attacked->x, $body_attacked->y, $body_attacked->name, $self->body->empire_id, $self->body->empire->name],
      );
    }

    $logs->new({
      date_stamp => DateTime->now,
      attacking_empire_id     => $self->body->empire_id,
      attacking_empire_name   => $self->body->empire->name,
      attacking_body_id       => $self->body_id,
      attacking_body_name     => $self->body->name,
      attacking_unit_name     => $self->name,
      attacking_type          => $self->type_formatted,
      attacking_number        => 1,
      defending_empire_id     => $empire->id,
      defending_empire_name   => $empire->name,
      defending_body_id       => $body_attacked->id,
      defending_body_name     => $body_attacked->name,
      defending_unit_name     => 'Excavator',
      defending_type          => 'Excavator',
      defending_number        => 1,
      attacked_empire_id      => $empire->id,
      attacked_empire_name    => $empire->name,
      attacked_body_id        => $body_attacked->id,
      attacked_body_name      => $body_attacked->name,
      victory_to              => 'attacker',
    })->insert;
    $ecount++;
    $excav->delete;
  }
  # notify about destruction
  $self->body->add_news(20, "A bright flash was observed on the surface of %s today.", $body_attacked->name);
  unless ($self->body->empire->skip_attack_messages) {
    my $filename; my $params;
    if ($mcount > 0 and $ecount > 0) {
      $filename = "detonator_destroyed_mining_excavators.txt";
      $params = [$mcount, $ecount, $body_attacked->x, $body_attacked->y, $body_attacked->name];
    }
    elsif ($mcount > 0) {
      $filename = "detonator_destroyed_mining_platforms.txt";
      $params = [$mcount, $body_attacked->x, $body_attacked->y, $body_attacked->name];
    }
    elsif ($ecount > 0) {
      $filename = "detonator_destroyed_excavators.txt";
      $params = [$ecount, $body_attacked->x, $body_attacked->y, $body_attacked->name];
    }
    else {
      $filename = "detonator_wasted.txt";
      $params = [$body_attacked->x, $body_attacked->y, $body_attacked->name];
    }
    $self->body->empire->send_predefined_message(
      tags        => ['Attack','Alert'],
      filename    => $filename,
      params      => $params,
    );
  }

  # it's all over but the cryin
  $self->delete;
  confess [-1];
};

1;
