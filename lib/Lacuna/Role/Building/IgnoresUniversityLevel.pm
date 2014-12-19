package Lacuna::Role::Building::IgnoresUniversityLevel;

use Moose::Role;

override _build_effective_level => sub {
    my ($self) = shift;
    $self->level;
};

1;

