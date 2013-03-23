package Lacuna::Role::Building::FormsNaturally;

use Moose::Role;

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(ref $self, 1)) {
        return $self->$orig($body);
    }
    confess [1013,"You can't build ".$self->name.". It forms naturally."];
};

1;

