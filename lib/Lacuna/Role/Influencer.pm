package Lacuna::Role::Influencer;

use Moose::Role;

before demolish => sub {
    my $self = shift;
    $self->body->update_influence;
};

before downgrade => sub {
    my $self = shift;
    $self->body->update_influence;
};

after finish_upgrade => sub {
    my $self = shift;
    $self->body->update_influence;
};

1;
