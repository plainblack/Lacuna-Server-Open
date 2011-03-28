package Lacuna::Role::Influencer;

use Moose::Role;

before demolish => sub {
    my $self = shift;
    my $station = $self->body;
    my $influence_remaining = $station->influence_remaining - $self->level;
    my $laws = $station->laws->search({type => 'Jurisdiction'},{order_by => { -desc => 'date_enacted'}});
    while (my $law = $laws->next) {
        last if $influence_remaining >= 0;
        $law->delete;
        $influence_remaining++;
    }
};

before downgrade => sub {
    my $self = shift;
    my $station = $self->body;
    my $influence_remaining = $station->influence_remaining - 1;
    my $laws = $station->laws->search({type => 'Jurisdiction'},{order_by => { -desc => 'date_enacted'}});
    while (my $law = $laws->next) {
        last if $influence_remaining >= 0;
        $law->delete;
        $influence_remaining++;
    }
};

1;
