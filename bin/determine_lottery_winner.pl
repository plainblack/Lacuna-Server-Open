use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date to_seconds randint);
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

my $cache = Lacuna->cache;
my $ymd = DateTime->now->subtract(days=>1)->ymd;
my $empire_id = $cache->get('high_vote_empire', $ymd);
if ($empire_id) {
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
    if ($empire) {
        $empire->add_essentia('Entertainment District Lottery');
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'we_won_the_lottery.txt',
        );
        $empire->home_planet->add_news(70,'And the winning numbers are...'.randint(10,99).', '.randint(10,99).', and '.randint(10,99).'...%s has won today\'s lottery!', $empire->name);
    }
}

my $finish = DateTime->now;
out('Finished');
out((to_seconds($finish - $start)/60)." minutes have elapsed");


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


