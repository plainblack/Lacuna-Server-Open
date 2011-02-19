package Lacuna::Role::Ship::Arrive::DestroyMiningPlatforms;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');

	# not an asteroid
	return if ($target->isa('Lacuna::DB::Result::Map::Body::Star'));

    # find mining platforms to destroy
    my $platforms = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->search({star_id => $self->foreign_body_id });
    my $count;

    # destroy those suckers
    while (my $platform = $platforms->next) {
        $probe->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'mining_platform_destroyed.txt',
            params      => [$self->foreign_body->x, $self->foreign_body->y, $self->foreign_body->name, $self->body->empire_id, $self->body->empire->name],
        );
        $count++;
        $probe->delete;
    }

    # notify about destruction
    $self->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'detonator_destroyed_mining_platforms.txt',
        params      => [$count, $self->foreign_body->x, $self->foreign_body->y, $self->foreign_body->name],
    );

    # it's all over but the cryin
    $self->delete;
    confess [-1];
};

1;
