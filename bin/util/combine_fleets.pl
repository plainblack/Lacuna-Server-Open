use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server/lib';
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

out('Touch all fleets');
my $fleets = $db->resultset('Lacuna::DB::Result::Fleet')->search;

while (my $fleet = $fleets->next) {
    eval {
        out("Update fleet [".$fleet->mark."]");
        $fleet->mark('one');
        $fleet->update;
    };    
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

sub out {
    my ($message) = @_;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}

