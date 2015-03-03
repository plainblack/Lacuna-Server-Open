use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date randint);
use Getopt::Long;
$|=1;

our $quiet;

GetOptions(
    'quiet'         => \$quiet,  
);

out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
our $config = Lacuna->config;
our $cache = Lacuna->cache;
our $news = $db->resultset('Lacuna::DB::Result::News');
our $empires = $db->resultset('Lacuna::DB::Result::Empire');
my $ymd = DateTime->now->subtract(days=>1)->ymd;
X: foreach my $x (int($config->get('map_size/x')->[0]/250) .. int($config->get('map_size/x')->[1]/250)) {
    Y: foreach my $y (int($config->get('map_size/y')->[0]/250) .. int($config->get('map_size/y')->[1]/250)) {
        my $zone = $x.'|'.$y;
        say $zone;
        my $empire_id = $cache->get('high_vote_empire'.$zone, $ymd);
        if ($empire_id) {
            my $empire = $empires->find($empire_id);
            if ($empire) {
                out('Winner: '.$empire->name);
                $empire->add_essentia({
                    amount  => 10, 
                    reason  => 'Entertainment District Lottery',
                });
                $empire->update;
                $empire->send_predefined_message(
                    tags        => ['Alert'],
                    filename    => 'we_won_the_lottery.txt',
                    params      => [ $zone ],
                );
                $news->new({
                    headline    => sprintf('And the winning numbers are...'.randint(10,99).', '.randint(10,99).', and '.randint(10,99).'...%s has won today\'s lottery!', $empire->name),
                    zone        => $zone,
                })->insert;
            }
        }
    }
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


