use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna;
use Lacuna::Util qw(format_date);
use DBI;
use Getopt::Long;
$|=1;

our $quiet;

GetOptions(
    'quiet'         => \$quiet,
);

out('Started');
my $start = time;

out('Loading DB');
my $config = Lacuna->config->get('db-reboot');
my $db = DBI->connect($config->{dsn}, $config->{username}, $config->{password});
$db->do("update taxes set paid_6 = paid_5, paid_5 = paid_4, paid_4 = paid_3, paid_3 = paid_2, paid_2 = paid_1, paid_1 = paid_0, paid_0 = 0");

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


