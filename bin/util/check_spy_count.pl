use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);


out('Started');
my $start = DateTime->now;

out('Loading DB');
our $db = Lacuna->db;
my $empires = $db->resultset('Lacuna::DB::Result::Empire');
my $bodies  = $db->resultset('Lacuna::DB::Result::Map::Body');
my $spies   = $db->resultset('Lacuna::DB::Result::Spies');
while (my $empire = $empires->next) {
#    next if $empire->id < 2;
    my $emp_spies = $spies->search({empire_id=>$empire->id}, {order_by => { -desc => 'level'}});
    my $emp_bodies = $bodies->search({empire_id=>$empire->id});
    my $total_allowed_spies = 0;
    my $total_spies = 0;
    my $int_min_stat = {};
    while (my $body = $emp_bodies->next) {
        my $bid = $body->id;
        my $int_min = $body->get_building_of_class('Lacuna::DB::Result::Building::Intelligence');
        if (defined($int_min) and ($int_min->max_spies < $int_min->spy_count)) {
            out(sprintf("Empire: %20s Planet: %20s:%8d Max:%2d Count: %3d", $empire->name, $body->name, $body->id, $int_min->max_spies, $int_min->spy_count));
        }
    }
# Write out excess training
}
out('All done');

###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


