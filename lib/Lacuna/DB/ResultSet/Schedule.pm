package Lacuna::DB::ResultSet::Schedule;

use Moose;
use utf8;
no warnings qw(uninitialized);

extends 'Lacuna::DB::ResultSet';

# Find an existing schedule, and reschedule it
#
sub reschedule {
    my ($self, $args) = @_;

    my ($schedule) = $self->search({
        parent_table    => $args->{parent_table},
        parent_id       => $args->{parent_id},
        task            => $args->{task},
    });
    $schedule->delete if defined $schedule;

    $schedule = $self->create($args);
    return $schedule;
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

