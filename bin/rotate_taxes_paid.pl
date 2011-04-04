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

advance();


my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

sub advance {
    $db->do("update taxes set paid_6 = paid_5, paid_5 = paid_4, paid_4 = paid_3, paid_3 = paid_2, paid_2 = paid_1, paid_1 = paid_0, paid_0 = 0");
}


# UTILITIES

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


