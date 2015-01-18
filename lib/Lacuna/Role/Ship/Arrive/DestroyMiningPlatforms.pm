package Lacuna::Role::Ship::Arrive::DestroyMiningPlatforms;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');

	# not an asteroid
	return unless ( $self->foreign_body_id && $self->foreign_body->isa('Lacuna::DB::Result::Map::Body::Asteroid') );

    # find mining platforms to destroy
    my $platforms = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->search({asteroid_id => $self->foreign_body_id });
    my $count;

    # destroy those suckers
    my $body_attacked = $self->foreign_body;
    my $logs = Lacuna->db->resultset('Lacuna::DB::Result::Log::Battles');

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
        $count++;
        $platform->delete;
    }

    # notify about destruction
    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'detonator_destroyed_mining_platforms.txt',
            params      => [$count, $body_attacked->x, $body_attacked->y, $body_attacked->name],
        );
    }

    # it's all over but the cryin
    $self->delete;
    confess [-1];
};

1;
