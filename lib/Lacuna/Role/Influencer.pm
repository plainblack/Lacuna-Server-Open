package Lacuna::Role::Influencer;

use Moose::Role;

before demolish => sub {
    my $self = shift;
    my $station = $self->body;
    my $influence_remaining = $station->influence_remaining - $self->effective_level;
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

    my @laws = $station->laws->search({type => 'Jurisdiction'},{order_by => { -desc => 'date_enacted'}})->all;

    # If this is an IBS, we must remove soon-to-be out of range star seizures now instead
    # of after downgrade, since that may make removing any others unnecessary and improper
    if ($self->isa('Lacuna::DB::Result::Building::Module::IBS')) {
        my $range_of_influence = $station->range_of_influence - 1000;
        for (my $law_index = $#laws; $law_index >= 0; --$law_index ) {
            my $law = $laws[$law_index];
            if ($station->calculate_distance_to_target($law->star) > $range_of_influence) {
                $law->delete;
                splice @laws, $law_index, 1;
            }
        }
    }

    my $influence_remaining = $station->influence_remaining - 1;
    for my $law (@laws) {
        last if $influence_remaining >= 0;
        $law->delete;
        $influence_remaining++;
    }
};

after finish_upgrade => sub {
    my $self = shift;
    my $station = $self->body;
    my $influence_remaining = $station->influence_remaining;
    my $laws = $station->laws->search({type => 'Jurisdiction'},{order_by => { -desc => 'date_enacted'}});
    while (my $law = $laws->next) {
        last if $influence_remaining >= 0;
        $law->delete;
        $influence_remaining++;
    }
};

1;
