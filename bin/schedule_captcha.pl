use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Lacuna::CaptchaFactory;

use Getopt::Long;
use App::Daemon qw(daemonize );
use Data::Dumper;
use Try::Tiny;
use Log::Log4perl qw(:levels);

# --------------------------------------------------------------------
# command line arguments:
#
my $daemonize   = 1;    # run the script as a daemon
my $initialize  = 1;    # (re)initialize the queue from the database
our $quiet      = 1;    # don't output any text

GetOptions(
    'daemonize!'    => \$daemonize,
    'quiet!'        => \$quiet,
    'initialize!'   => \$initialize,
);

$App::Daemon::loglevel = $quiet ? $WARN : $DEBUG;
$App::Daemon::logfile  = '/tmp/schedule_captcha.log';
$App::Daemon::as_user  = 'root';
$App::Daemon::as_group = 'root';

chdir '/data/Lacuna-Server/bin';

my $pid_file        = '/data/Lacuna-Server/bin/schedule_captcha.pid';

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
eval {
    
    LOOP: do {
        my $job     	= $queue->consume('captcha');
    
        out('job received ['.$job->id.']');

        try {
            # process the job

            my $captcha = Lacuna::CaptchaFactory->new({
                develop_mode    => $config->get('develop_mode') ? 1 : 0,
                fonts           => $config->get('captcha/fonts'),
                font_path       => $config->get('captcha/fontpath'),
            });
            $captcha->construct;
            out("Captcha created [".$captcha->guid."]");

            # Remove all captchas older than 1hr (except for one)
            #
            # select * from captcha where created < DATE_SUB(now(), INTERVAL 1 HOUR) order by id desc;
            #
            my $captchas = Lacuna->db->resultset('Captcha')->search({
                created => \"< DATE_SUB(now(), INTERVAL 1 HOUR)",
            },{
                order_by => { -desc => 'id' },
            });
            # Make sure there is at least one left irrespective of it's age
            my $captcha = $captchas->next;

            while ($captcha = $captchas->next) {
                out("Deleting captcha [".$captcha->id."]");

                my $prefix  = substr($captcha->guid, 0,2);
                my $file    = "/data/captcha/$prefix/".$captcha->guid.".png";
                out("Deleting file [$file]");
                unlink($file);
                $captcha->delete;
            }

            out("Processing done. Delete job ".$job->id);
            $job->delete;
        }
        catch {
            # bury the job, it failed
            out("Job ".$job->id." failed: $_");
            $job->bury;
        };
    } while (1);
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
    print STDERR $message."\n";
    $logger->info($message);
}

