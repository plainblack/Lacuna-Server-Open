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
use Log::Log4perl qw(:levels);

# --------------------------------------------------------------------
# command line arguments:
#
my $daemonize   = 1;    # run the script as a daemon
my $loop        = 1;    # loop continuously waiting for jobs
my $initialize  = 1;    # (re)initialize the queue from the database
my $timeout     = 1;    # timeout after an hour
our $quiet      = 1;    # don't output any text

GetOptions(
    'daemonize!'    => \$daemonize,
    'loop!'         => \$loop,
    'quiet!'        => \$quiet,
    'initialize!'   => \$initialize,
    'timeout!'      => \$timeout,
);

$App::Daemon::loglevel = $quiet ? $WARN : $DEBUG;
$App::Daemon::logfile  = '/tmp/schedule_building.log';

chdir '/data/Lacuna-Server/bin';

my $timeout_seconds = 60 * 60; # (one hour)
my $pid_file        = '/data/Lacuna-Server/bin/schedule_building.pid';

my $start = time;

# kill any existing processes
#
if (-f $pid_file) {
    open(PIDFILE, $pid_file);
    my $PID = <PIDFILE>;
    chomp $PID;
    if (grep /$PID/, `ps -p $PID`) {
        close (PIDFILE);
        out("Killing previous job, PID=$PID");
        kill 9, $PID;
        sleep 5;
    }
}

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
        my $schedule = Lacuna->db->resultset('Schedule')->create({
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
        my $schedule = Lacuna->db->resultset('Schedule')->create({
            delivery        => $building->upgrade_ends,
            parent_table    => 'Building',
            parent_id       => $building->id,
            task            => 'finish_upgrade',
        });
    }

    out('Adding ship builds');
    my $ship_rs = Lacuna->db->resultset('Ships')->search({
        task => 'Building',
    });
    while (my $ship = $ship_rs->next) {
        # add to queue
        my $schedule = Lacuna->db->resultset('Schedule')->create({
            delivery        => $ship->date_available,
            parent_table    => 'Ships',
            parent_id       => $ship->id,
            task            => 'finish_construction',
        });
    }
}

# --------------------------------------------------------------------
# Daemonize

if ($daemonize) {
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
# Timeout after an hour
eval {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm $timeout_seconds if $timeout;
    
    LOOP: do {
        my $job     = $queue->consume('default');
        my $args    = $job->args;
        $job->delete, next unless ref $args eq 'HASH';
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
};
if ($@) {
    die unless $@ eq "alarm\n"; # propagate unexpected errors
    # timed out
}

my $finish = time;
out('Finished');
out(int(($finish - $start)/60)." minutes have elapsed");
exit 0;

###############
## SUBROUTINES
###############

sub out {
    my ($message) = @_;
    my $logger = Log::Log4perl->get_logger;
    $logger->info($message);
}

