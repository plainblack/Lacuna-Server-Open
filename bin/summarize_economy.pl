use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use DateTime;
use DateTime::Format::Strptime;
use feature "switch";


$|=1;
our $quiet;
our $all;
GetOptions(
    'quiet'         => \$quiet,
    'all'           => \$all,
);


out('Started');
my $start = DateTime->now;

out('Loading DB');
our $db = Lacuna->db;
our $viral_log = $db->resultset('Lacuna::DB::Result::Log::Viral');
our $economy_log = $db->resultset('Lacuna::DB::Result::Log::Economy');
our $essentia_log = $db->resultset('Lacuna::DB::Result::Log::Essentia');


if ($all) {
    $economy_log->delete;
    my $oldest = $essentia_log->search->get_column('date_stamp')->min;
    $oldest = DateTime::Format::Strptime->new(pattern=>'%F')->parse_datetime($oldest);
    while ($oldest < $start) {
        summarize($oldest);
        $oldest->add(days=>1);
    }
}
else {
    summarize(DateTime->now->subtract(hours=>1));
}


my $finish = time;
out('Finished');
out((($finish - $start->epoch)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

sub summarize {
    my $date = shift;
    out('Summarizing Economy For '.$date->ymd);
    my $today = $economy_log->search({date_stamp => $date->ymd},{rows=>1})->single;
    if (defined $today) {
        $today->delete;
    }
    $today = $economy_log->new({ date_stamp => $date->ymd });
    my $viral = $viral_log->search({date_stamp => $date->ymd},{rows=>1})->single;
    if (defined $viral) {
        $today->total_users($viral->total_users);
    }
    my $entries = $essentia_log->search({date_stamp => {between => [$date->ymd, $date->ymd.' 23:59:59']}});
    while (my $entry = $entries->next) {
        given ($entry->description) {
            when (/Purchased via/) {
                $today->in_purchase( $today->in_purchase + $entry->amount);            
                if ($entry->amount == 30) {
                    $today->purchases_30( $today->purchases_30 + 1);
                }
                elsif ($entry->amount == 100) {
                    $today->purchases_100( $today->purchases_100 + 1);
                }
                elsif ($entry->amount == 200) {
                    $today->purchases_200( $today->purchases_200 + 1);
                }
                elsif ($entry->amount == 600) {
                    $today->purchases_600( $today->purchases_600 + 1);
                }
                elsif ($entry->amount == 1300) {
                    $today->purchases_1300( $today->purchases_1300 + 1);
                }
            }
            when ('Essentia Vein') {
                $today->in_vein( $today->in_vein + $entry->amount);            
            }
            when ('tutorial') {
                $today->in_tutorial( $today->in_tutorial + $entry->amount);            
            }
            when ('Essentia Code Redemption') {
                $today->in_redemption( $today->in_redemption + $entry->amount);            
            }
            when ('Entertainment District Lottery') {
                $today->in_vote( $today->in_vote + $entry->amount);            
            }
            when (/trade/i) {
                if ($entry->amount < 0) {
                    $today->out_trade( $today->out_trade + ($entry->amount * -1));            
                }
                else {
                    $today->in_trade( $today->in_trade + $entry->amount);            
                }
            }
            when (/mission/i) {
                if ($entry->amount < 0) {
                    $today->out_mission( $today->out_mission + ($entry->amount * -1));            
                }
                else {
                    $today->in_mission( $today->in_mission + $entry->amount);            
                }
            }
            when (/boost/i) {
                $today->out_boost( $today->out_boost + ($entry->amount * -1));            
            }
            when (/spy training subsidy/i) {
                $today->out_spy( $today->out_spy + ($entry->amount * -1));            
            }
            when (/recycling subsidy/i) {
                $today->out_recycle( $today->out_recycle + ($entry->amount * -1));            
            }
            when (/ship build subsidy/i) {
                $today->out_ship( $today->out_ship + ($entry->amount * -1));            
            }
            when (/glyph search subsidy/i) {
                $today->out_glyph( $today->out_glyph + ($entry->amount * -1));            
            }
            when (/party subsidy/i) {
                $today->out_party( $today->out_party + ($entry->amount * -1));            
            }
            when (/construction subsidy/i) {
                $today->out_building( $today->out_building + ($entry->amount * -1));            
            }
            when ('empire deleted') {
                $today->out_delete( $today->out_delete + ($entry->amount * -1));            
            }
            default {
                if ($entry->amount < 0) {
                    $today->out_other( $today->out_other + ($entry->amount * -1));            
                }
                else {
                    $today->in_other( $today->in_other + $entry->amount);            
                }
            }
        }
    }
    $today->insert;
}


sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


