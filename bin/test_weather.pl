use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use utf8;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);


out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

my $planet_rs = $db->resultset('Map::Body');

out(join(',', "Planet ID","Class","Water","Gold"));
foreach my $type (qw(P33 P34 P35 P36)) {
    my @planets = $planet_rs->search(
        {class      => "Lacuna::DB::Result::Map::Body::Planet::$type"},
        {order_by   => 'id', rows => 5});
    foreach my $planet (@planets) {
        out(join(',', $planet->id,$type,$planet->water,$planet->gold));
    }
}



###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


