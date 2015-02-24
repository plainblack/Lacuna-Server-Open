package Lacuna::DB::Result::Schedule;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use DateTime;
use Scalar::Util qw(weaken);
use Lacuna::Util qw(format_date);
use Digest::SHA;
use List::MoreUtils qw(uniq);
use Email::Stuff;
use Email::Valid;
use UUID::Tiny ':std';
use Lacuna::Constants qw(INFLATION);
use Data::Dumper;

extends 'Lacuna::DB::Result';

__PACKAGE__->table('schedule');
__PACKAGE__->add_columns(
    queue        => {data_type => 'varchar', size => 30, is_nullable => 0},
    job_id       => {data_type => 'int', size => 11, is_nullable => 0},
    delivery     => {data_type => 'datetime', is_nullable => 0},
    priority     => {data_type => 'int', size => 11, is_nullable => 0, default_value => 1000},
    parent_table => {data_type => 'varchar', size => 30, is_nullable => 0},
    parent_id    => {data_type => 'int', size => 11, is_nullable => 0},
    task         => {data_type => 'varchar', size => 30, is_nullable => 0},
    args         => {data_type => 'mediumblob', is_nullable => 1, serializer_class => 'JSON'},
);

after 'insert' => sub {
    my $self = shift;

    if (Lacuna->config->get('beanstalk')) {
        # an enhancement would to only put entries on beanstalk that are due within the hour
        # and also have an hourly cron job for entries that became due in the following hour
        $self->queue_for_delivery;
    }
    return $self;
};

before 'delete' => sub {
    my $self = shift;
   
    if (Lacuna->config->get('beanstalk')) {
        my $queue = Lacuna->queue;
        # Delete the job off the queue
        $queue->delete($self->job_id);
    }
};


# Put this entry onto the beanstalk queue
#
sub queue_for_delivery {
    my ($self) = @_;

    my $now_epoch   = DateTime->now->epoch;
    my $delivery    = $self->delivery;
    my $del_epoch   = $delivery->epoch;
    my $delay       = $del_epoch - $now_epoch;
    $delay = 0 if $delay < 0;
    my $now         = DateTime->now;

    my $queue       = Lacuna->queue;
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

