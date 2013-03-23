use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;

# Routine to convert hall buildings, back into plans.

$|=1;
our $quiet;
our $body_id;
our $class;
our $count;

out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

my $body_rs = $db->resultset('Map::Body')->search({
    empire_id   => { '!=' => 0 },
});

while (my $body = $body_rs->next) {
    my $stats_body_name = $body->name;

    # Get all Hall buildings
    my @halls = $body->get_buildings_of_class('Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk');
    my $stats_hall_buildings = scalar(@halls);
    my $hall_plans = $body->get_plan('Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk', 1);
    my $stats_hall_plans = defined $hall_plans ? $hall_plans->quantity : 0;
    out("Planet $stats_body_name - hall_buildings=$stats_hall_buildings - hall_plans=$stats_hall_plans");
    if ($stats_hall_buildings) {
        $body->delete_buildings(\@halls);
        $body->add_plan('Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk',1,0,$stats_hall_buildings);
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


