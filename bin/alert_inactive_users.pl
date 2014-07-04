use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
$|=1;

our $quiet;
our $all;
GetOptions(
    'quiet'         => \$quiet,
    'all'           => \$all,
);

out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire');
my $ymd = DateTime->now->subtract( days => 5)->ymd;

if ($all) {
    $empires = $empires->search({
        last_login  => { '<' => $ymd.' 00:00:00'}
    });
}
else {
    $empires = $empires->search({
        last_login  => { 'between' => [$ymd.' 00:00:00', $ymd.' 23:59:59']}
    });
}

my $config = Lacuna->config;
my $server_url = $config->get('server_url');
my $inactivity_time_out = $config->get('self_destruct_after_inactive_days') || 20;
while (my $empire = $empires->next) {
    out($empire->name);
    my $ttl =  $inactivity_time_out - sprintf('%0.f',($start - $empire->last_login->epoch) / (60 * 60 * 24) );
    $empire->send_email('We Miss You',
        $empire->name
        .",\n\nIt has been a while since we have seen you around the Lacuna Expanse, and we have missed you. It is important that you log in regularly because your empire will automatically activate its self-destruct sequence in "
        .$ttl
        ." days.\n\n"
        .$server_url
    );
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############




# UTILITIES

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


