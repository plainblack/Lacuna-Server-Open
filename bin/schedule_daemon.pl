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
our $quiet      = 1;

GetOptions(
    'daemonise!'    => \$daemonise,
    'loop!'         => \$loop,
    'quiet!'        => \$quiet,
);

# Catch SIG INT
#
#my $sig_int = 0;
#local $SIG{'INT'} = sub { $sig_int = 1; };
my $start = time;

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
#    if ($sig_int) {
#        out('Received INT signal, jumping out of polling loop');
#        undef $loop;
#    }
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

