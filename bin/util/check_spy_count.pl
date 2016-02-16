use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
our $burn;
GetOptions(
    'quiet'         => \$quiet,  
    'burn'          => \$burn,  
);


out('Started');
my $start = DateTime->now;

out('Loading DB');
our $db = Lacuna->db;
my $empires = $db->resultset('Lacuna::DB::Result::Empire');
my $bodies  = $db->resultset('Lacuna::DB::Result::Map::Body');
my $spies   = $db->resultset('Lacuna::DB::Result::Spies');
while (my $empire = $empires->next) {
    next if $empire->id < 2;
    my $emp_bodies = $bodies->search({empire_id=>$empire->id});
    my $int_min_stat = {};
    while (my $body = $emp_bodies->next) {
        my $bid = $body->id;
        my $int_min = $body->get_building_of_class('Lacuna::DB::Result::Building::Intelligence');
        if (defined($int_min) and ($int_min->max_spies < $int_min->spy_count)) {
            out(sprintf("Empire: %20s Planet: %20s:%8d Max:%2d Count: %3d", $empire->name, $body->name, $body->id, $int_min->max_spies, $int_min->spy_count));
            my $bod_spies = $spies->search({from_body_id=>$bid}, {order_by => { -desc => 'id'}});
            my $burned = 0;
            my $to_burn = $int_min->spy_count - $int_min->max_spies;
            while (my $spy = $bod_spies->next) {
                out(sprintf("Spy: %8d stops %s : O:%4d D:%4d I:%4d M:%4d P:%4d T:%4d",
                             $spy->id, $spy->task,
                             $spy->offense, $spy->defense,
                             $spy->intel_xp, $spy->mayhem_xp, $spy->politics_xp, $spy->theft_xp));
                if ($burn) {
                    $spy->update({
                                  task => 'Retiring',
                                  defense_mission_count => 150,
                                  offense_mission_count => 150,
                                  available_on => DateTime->now->add(years => 5),
                         });
                }
                $burned++;
                last if ($burned >= $to_burn);
            }
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


