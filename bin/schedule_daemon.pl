use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use App::Daemon qw(daemonize );
use Data::Dumper;
use Try::Tiny;

$|=1;

# --------------------------------------------------------------------
# command line arguments:
#
my $daemonise   = 1;
my $loop        = 1;
my $initialize  = 1;
our $quiet      = 1;

GetOptions(
    'daemonise!'    => \$daemonise,
    'loop!'         => \$loop,
    'quiet!'        => \$quiet,
    'initialize!'   => \$initialize,
);

my $start = time;

if ($initialize) {
    # (re)initialize all the jobs on the queues, replacing any 
    # existing jobs
    out('Reinitializing all jobs');
    out('Deleting existing jobs');
    my $schedule_rs = Lacuna->db->resultset('Schedule')->search;
    while (my $schedule = $schedule_rs->next) {
        # note. deleting the DB entry also deletes the entry on beanstalk
        $schedule->delete;
    }

    out('Adding building upgrades');
    my $building_rs = Lacuna->db->resultset('Building')->search({
        is_working => 1,
    });
    while (my $building = $building_rs->next) {
        # add to queue
        out('Building - finish_work at '.$building->work_ends);
        Lacuna->db->resultset('Schedule')->create({
            delivery        => $building->work_ends,
            parent_table    => 'Building',
            parent_id       => $building->id,
            task            => 'finish_work',
        });
    }

    out('Adding building working end');
    $building_rs = Lacuna->db->resultset('Building')->search({
        is_upgrading => 1,
    });
    while (my $building = $building_rs->next) {
        # add to queue
        out('Building - finish_upgrade at '.$building->upgrade_ends);
        Lacuna->db->resultset('Schedule')->create({
            delivery        => $building->upgrade_ends,
            parent_table    => 'Building',
            parent_id       => $building->id,
            task            => 'finish_upgrade',
        });
    }

    out('Adding ship building ends');
    my $dt_parser   = Lacuna->db->storage->datetime_parser;
    my $now         = $dt_parser->format_datetime( DateTime->now );
    my $fleets = Lacuna->db->resultset('Fleet')->search({
        date_available  => { '<=' => $now },
        task            => 'Travelling',
    });
    while (my $fleet = $fleets->next ) {
        if ($fleet->task eq 'Travelling') {
            out('Fleet - arrive at '.$fleet->date_available);
            Lacuna->db->resultset('Schedule')->create({
                delivery        => $fleet->date_available,
                parent_table    => 'Fleet',
                parent_id       => $fleet->id,
                task            => 'arrive',
            });
        }
        elsif ($fleet->task eq 'Building') {
            out('Fleet - finish_work at '.$fleet->date_available);
            Lacuna->db->resultset('Schedule')->create({
                delivery        => $fleet->date_available,
                parent_table    => 'Fleet',
                parent_id       => $fleet->id,
                task            => 'finish_work',
            });
        }
    }
}

# --------------------------------------------------------------------
# Daemonise

if ($daemonise) {
    daemonize();
    out('Running as a daemon');
}
else {
    out('Running in the foreground');
}

my $config = Lacuna->config;

my $queue = Lacuna::Queue->new({
    max_timeouts    => $config->get('beanstalk/max_timeouts'),
    max_reserves    => $config->get('beanstalk/max_reserves'),
    server          => $config->get('beanstalk/server'),
    ttr             => $config->get('beanstalk/ttr'),
    debug           => $config->get('beanstalk/debug'),
});

out("queue = $queue");

# --------------------------------------------------------------------
# Main processing loop

out('Started');
do {
    out('In Main Processing Loop');
    my $job     = $queue->consume('default');
    my $args    = $job->args;
    my $task    = $args->{task};
    my $task_args = $args->{args};

    out('job received ['.$job->id.']');

    my $payload = $job->payload;

    try {
        # process the job
        out("Process class=$payload task=$task");
        $payload->$task($task_args);
        out("Processing done. Delete job ".$job->id);
        $job->delete;
    }
    catch {
        # bury the job, it failed
        out("Job ".$job->id." failed: $_");
        $job->bury;
    };
} while ($loop);

my $finish = time;
out('Finished');
out(int(($finish - $start)/60)." minutes have elapsed");
exit 0;

###############
## SUBROUTINES
###############

sub out {
    my ($message) = @_;
    if (not $quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}

