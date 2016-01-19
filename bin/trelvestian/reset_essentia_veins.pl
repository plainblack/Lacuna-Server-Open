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
        my $ends = DateTime->now->add(seconds => 60*60*24*60);
        $vein->level(28);
        $vein->reschedule_work($ends)->update;
    }
    else {
        my $buildings = $db->resultset('Lacuna::DB::Result::Building');
        my ($x, $y) = $colony->find_free_space;
        my $building = $buildings->new({
            class   => 'Lacuna::DB::Result::Building::Permanent::EssentiaVein',
            level   => 28,
            x       => $x,
            y       => $y,
            body_id => $colony->id,
            body    => $colony,
        });
        out('Added ' . $building->name);
        $colony->build_building($building);
        $building->finish_upgrade;
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


