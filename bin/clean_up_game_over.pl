use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint format_date);
use Config::JSON;
use Lacuna::Cache;
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);


out('Started');
my $start = DateTime->now;

out('Checking server status');
my $config = Config::JSON->new('/data/Lacuna-Server-Open/etc/reboot.conf');
my $cache = Lacuna::Cache->new(servers => $config->get('memcached'));
my $status = $cache->get('server','status');
unless ( $status eq 'Game Over' ) {
    out('Server status is ' . $status);
    exit 1;
}

out('Loading DB');
our $db = Lacuna->db;
my $empires = $db->resultset('Lacuna::DB::Result::Empire')->search({id => { '>' => 1 } });

out('Deleting Empires');
while (my $empire = $empires->next) {
    out('Deleting Empire: '. $empire->name);
    $empire->delete;
}

my $finish = time;
out('Finished');
out((($finish - $start->epoch)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


