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
    my ($x, $y) = $body_attacked->find_free_space;
    my $deployed = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        class       => 'Lacuna::DB::Result::Building::Permanent::Crater',
        x           => $x,
        y           => $y,
    });
    $deployed->start_work({},3600 * randint(24,168));
    $body_attacked->build_building($deployed);
    
    # notify home
    $self->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'thud_hit_target.txt',
        params      => [$body_attacked->x, $body_attacked->y, $body_attacked->name],
    );

    # notify attacked
    $body_attacked->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'thud_hit_us.txt',
        params      => [$self->body->empire->id, $self->body->empire->name, $body_attacked->id, $body_attacked->name],
    );
    $body_attacked->add_news(70, sprintf("A quake measuring %.1f on the seismic magnitude scale just struck %s.",rand(10)));
    
    # all pow
    $self->delete;
    confess [-1];
};


1;
