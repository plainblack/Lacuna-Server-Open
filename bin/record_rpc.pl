use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);

out('Started');
my $start = DateTime->now;

out('Loading DB');
our $db = Lacuna->db;
my $empire_rs = $db->resultset('Empire');

out('Recording each empires previous day RPC count.');
# this assumes that this task runs before noon each day and that
# the memcache for the previous day has not yet expired.
my $now = DateTime->now;
my $yesterday = DateTime->now->subtract( hours => 12 );
my $yesterday_formatted = format_date($yesterday,'%d');
out ("Now is $now yesterday is $yesterday");

my $total_rpc       = 0;
my $total_limits    = 0;

while (my $empire = $empire_rs->next) {
    my $rpc = Lacuna->cache->get('rpc_count_'.$yesterday_formatted, $empire->id) || 0;
    my $limits = Lacuna->cache->get('rpc_limit_'.$yesterday_formatted, $empire->id) || 0;

    out("Empire [".$empire->name."] had [$rpc] RPC and [$limits] rate limits yesterday");

    next unless $rpc;

    my $log = $db->resultset('Log::EmpireRPC')->create({
        date_stamp  => $now,
        empire_id   => $empire->id,
        empire_name => $empire->name,
        rpc         => $rpc,
        limits      => $limits,
    });
    $total_rpc      += $rpc;
    $total_limits   += $limits;
}
$db->resultset('Log::EmpireRPC')->create({
    date_stamp  => $now,
    empire_id   => 0,
    empire_name => 'totals',
    rpc         => $total_rpc,
    limits      => $total_limits,
});
                                            

out("Total Empire wide had [$total_rpc] RPC and [$total_limits] rate limits yesterday");

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


