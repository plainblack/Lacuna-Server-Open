use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
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
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
our $ai = Lacuna::AI::Trelvestian->new;
my $config = Lacuna->config;

out('Looping through colonies...');
my $colonies = $ai->empire->planets;
while (my $colony = $colonies->next) {
    out('Found colony '.$colony->name);
    my $vein = $colony->get_building_of_class('Lacuna::DB::Result::Building::Permanent::EssentiaVein');
    if (defined $vein) {
        $vein->start_work({}, 60 * 60 * 24 * 60)->update;
    }
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");




###############
## SUBROUTINES
###############



sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


