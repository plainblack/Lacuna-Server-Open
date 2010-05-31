use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date to_seconds);
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

out('Processing planets');
my $planets = $db->resultset('Lacuna::DB::Result::Map::Body')->search({ empire_id   => {'>' => 0} });
while (my $planet = $planets->next) {
    out('Ticking '.$planet->name);
    $planet->tick;
    summarize_spies($planet);
}

my $finish = DateTime->now;
out('Finished');
out((to_seconds($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

sub summarize_spies {
    my $spies = $db->resultset('Lacuna::DB::Result::Spies');
    my $logs = $db->resultset('Lacuna::DB::Result::Log::Spies');
    while (my $spy = $spies->next) {
        my $log = $logs->search({ spy_id => $spy->id },{ rows => 1 } )->single;
	my $success_rate = ($spy->mission_count) ? $spy->mission_successes / $spy->mission_count : 0;
        if (defined $log) {
            $log->update({
                spy_name            => $spy->name,
                level               => $spy->level,
                level_delta         => $spy->level - $log->level,
                success_rate        => $success_rate,
                success_rate_delta  => $success_rate - $log->success_rate,
                age                 => to_seconds(DateTime->now - $spy->date_created),
            });
        }
        else {
            $logs->new({
                empire_id           => $spy->empire_id,
                empire_name         => $spy->empire->name,
                date_stamp          => DateTime->now,
                spy_name            => $spy->name,
                spy_id              => $spy->id,
                level               => $spy->level,
                level_delta         => 0,
                success_rate        => $success_rate,
                success_rate_delta  => 0,
                age                 => to_seconds(DateTime->now - $spy->date_created),
            })->insert;
        }
    }
}


# UTILITIES

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


