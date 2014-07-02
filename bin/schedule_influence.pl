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
# Description:
# This queue works a little differently from the ship building and the
# building upgrade queue.
# In this queue we don't care so much about individual space stations
# that need to have their influence recalculated. We can easily do a
# database query to get all SS which need to be recalculated.
#
# This allows us to perform some optimisations. 
#
# First we check all SS that need to be recalculated, we add (or delete)
# entries in the 'Influence' table and all stars which are affected are
# marked for a 'recalc'.
#
# Having processed all SS we then go through and recalc the influence on
# each star so marked.
#
# This means we don't un-necessarily calculate the influence on each star
# twice (e.g. when multiple nearby SS all change in a short space of time)
#
# Secondly we put a delay on recalculating each SS's influence. This is
# because it is likely that an update to an SS may result in multiple
# changes (e.g. several modules upgrade, get damaged together).
#
# The delay means we will capture all changes to the SS in (say) 20 minutes
# and just do the calculations once, not multiple times.
#
# The Influence job queue acts as a binary flag 'do all SS influence
# calculations now'. If there are none to do, it short circuits and does
# nothing.
#

# --------------------------------------------------------------------
# command line arguments:
#
my $daemonize   = 1;
my $loop        = 1;
my $initialize  = 1;
our $quiet      = 1;

GetOptions(
    'daemonize!'    => \$daemonize,
    'loop!'         => \$loop,
    'quiet!'        => \$quiet,
    'initialize!'   => \$initialize,
);

out('Got here') unless $quiet;

$App::Daemon::loglevel = $quiet ? $WARN : $DEBUG;
$App::Daemon::logfile  = '/tmp/schedule_influence.log';

chdir '/data/Lacuna-Server/bin';

my $timeout     = 60 * 60; # (one hour)
my $pid_file    = '/data/Lacuna-Server/bin/schedule_influence.pid';

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
my $queue = Lacuna->queue;

# Initialize simply mean we add one job on the queue which will
# run immediately.
if ($initialize) {
    # (re)initialize all the jobs on the queues, replacing any 
    # existing jobs
    out('Restarting all influence checks');

    # Add a single job to run immediately.
    $queue->publish('influence',{},{});
}

# --------------------------------------------------------------------
# Daemonize

if ($daemonize) {
    out('Running as a daemon');
    daemonize();
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
    alarm $timeout;
    my $db = Lacuna->db;

    LOOP: do {
        my ($job,$args);

        $job     = $queue->consume('influence');
        $args    = $job->args;
        $job->delete, next unless ref $args eq 'HASH';

        out('job received ['.$job->id.']');
        try {
            # check if there is anything to do
            my $station_rs = Lacuna->db->resultset('Lacuna::DB::Map::Body')->search({
                station_recalc  => 1,
            });
            while (my $station = $station_rs->next) {
                out('Processing station '.$station->name);
                $station->recalc_influence;
            }
            # Now check if there are any stars to recalculate
            my $star_rs = Lacuna->db->resultset('Map::Star')->search({
                recalc => 1,
            });
            while (my $star = $star_rs->next) {
                out('Processing star '.$star->name);
                $star->recalc_influence;
            }
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
    print STDERR "$message\n";
    my $logger = Log::Log4perl->get_logger;
    $logger->info($message);
}

