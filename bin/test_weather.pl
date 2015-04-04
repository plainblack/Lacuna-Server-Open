use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use Lacuna::Constants qw(ORE_TYPES);
use Data::Dumper;

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
my @ores = sort map {$_.''} ORE_TYPES;
my $title = "Planet ID,Class,Water,";
$title .= join ',', @ores;
print "$title\n";
foreach my $type (qw(P33)) {
    my @planets = $planet_rs->search(
        {class      => "Lacuna::DB::Result::Map::Body::Planet::$type"},
        {order_by   => 'id', rows => 5});
    foreach my $planet (@planets) {
        my $text = join(',', $planet->id,$type,$planet->water, map {$planet->$_} @ores);
        print "$text\n";
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


