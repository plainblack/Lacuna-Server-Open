package Lacuna::Role::Building::CantBuildWithoutPlan;

use Moose::Role;

around can_build => sub {
    my $orig = shift;
    my $self = shift;

    if ($self->body->get_plan(ref $self, 1)) {
        return $self->$orig(@_);
    }
    confess [1013,"You can't build ".$self->name.", unless you have a plan."];
};

1;

