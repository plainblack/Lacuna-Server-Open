package Lacuna::Role::Fleet::Send::SpendNextColonyCost;

use strict;
use Moose::Role;

after turn_around => sub {
    my $self = shift;
    $self->body->add_happiness($self->payload->{colony_cost})->update;
};

after can_send_to_target => sub {
    my ($self, $target) = @_;
    my $empire = $self->body->empire;
    my $next_colony_cost = $empire->next_colony_cost;
    confess [ 1011, 'You do not have enough happiness to colonize another planet. You need '.$next_colony_cost.' happiness.', [$next_colony_cost]] unless ( $self->body->happiness > $next_colony_cost);
    return 1;
};

after send => sub {
    my $self = shift;
    return if ($self->direction eq 'in');
    my $next_colony_cost = $self->body->empire->next_colony_cost(-1);
    $self->body->spend_happiness($next_colony_cost)->update;
    $self->payload({ colony_cost => $next_colony_cost });
    $self->update;
};

1;
