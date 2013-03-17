package Lacuna::Role::Building::CantBuildWithoutPlan;

use Moose::Role;

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);
    }
    confess [1013,"You can't build ".$self->name.", unless you have a plan."];
};

1;

