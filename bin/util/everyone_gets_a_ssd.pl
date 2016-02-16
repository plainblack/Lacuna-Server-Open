use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
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

out('Giving SSD');
my $empires = $db->resultset('Lacuna::DB::Result::Empire');
while (my $empire = $empires->next) {
    next unless $empire->tutorial_stage eq 'turing';
    my $home = $empire->home_planet;
    next unless defined $home;
    say "Adding to ".$home->name;
    my ($x, $y) = $home->find_free_space;
    my $ssd = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        body_id  => $home->id,
        x        => $x,
        y        => $y,
        class    => 'Lacuna::DB::Result::Building::SubspaceSupplyDepot',
     });
     $home->build_building($ssd);
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


