use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
our $body_id;
our $class;
our $count;
GetOptions(
    'quiet'         => \$quiet,  
    'body'          => \$body_id,
    'class'          => \$class,
    'count'         => \$count,
);

out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

my $body = $db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
unless ($body) {
    die "Cannot find body id $body_id";
}
say "Adding $count level 1 $class plans to $body->name";
for my $cnt ( 1 .. $count ) {
    $body->add_plan($class, 1, 0);
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


