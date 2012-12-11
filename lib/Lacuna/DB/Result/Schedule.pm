package Lacuna::DB::Result::Schedule;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;
use Data::Dumper;

__PACKAGE__->table('schedule');
__PACKAGE__->add_columns(
    queue        => {data_type => 'varchar', size => 30, is_nullable => 0},
    job_id       => {data_type => 'int', size => 11, is_nullable => 0},
    delivery     => {data_type => 'datetime', is_nullable => 0},
    priority     => {data_type => 'int', size => 11, is_nullable => 0, default => 1000},
    parent_table => {data_type => 'varchar', size => 30, is_nullable => 0},
    parent_id    => {data_type => 'int', size => 11, is_nullable => 0},
    task         => {data_type => 'varchar', size => 30, is_nullable => 0},
    args         => {data_type => 'medium_blob', is_nullable => 1, serializer_class => 'JSON'},
);

after 'insert' => sub {
    my $self = shift;

#    my $earliest = DateTime->now->add( hours => 2);
#    if ($self->delivery < $earliest) {
        # If delivery is within the next couple of hours
        # Then put it directly on the beanstalk queue
        $self->queue_for_delivery;
#    }
    return $self;
};


# Put this entry onto the beanstalk queue
#
sub queue_for_delivery {
    my ($self) = @_;

    my $dur     = $self->delivery->subtract_datetime_absolute(DateTime->now);
    my $delay   = int($dur->in_units('seconds'));
    $delay      = 0 if $delay < 0;

    my $queue   = Lacuna->queue || 'default';
    my $priority    = $self->priority || 1000;

    my $job = $queue->publish($self->queue,
        {
            id              => $self->id,
            parent_table    => $self->parent_table,
            parent_id       => $self->parent_id,
            task            => $self->task,
            args            => $self->args,
        },{
            delay           => $delay,
            priority        => $priority,
        }
    );
    $self->job_id($job->id);
    $self->update;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

