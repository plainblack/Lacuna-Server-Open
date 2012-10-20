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
my $spies   = $db->resultset('Lacuna::DB::Result::Spies');
my $bodies  = $db->resultset('Lacuna::DB::Result::Map::Body');

# Going to redo the level calc to account for training, more than base.
out('Updating spy level');
while (my $spy = $spies->next) {
  $spy->calculate_level;
}
out('wee!');
$spies   = $db->resultset('Lacuna::DB::Result::Spies');

while (my $empire = $empires->next) {
    next if $empire->id < 2;
    my $emp_spies = $spies->search({empire_id=>$empire->id}, {order_by => { -desc => 'level'}});
    my $emp_bodies = $bodies->search({empire_id=>$empire->id});
    my $total_allowed_spies = 0;
    my $total_spies = 0;
    while (my $body = $emp_bodies->next) {
        my $int_min = $body->get_building_of_class('Lacuna::DB::Result::Building::Intelligence');
        $total_allowed_spies += $int_min->max_spies if (defined($int_min));
        $total_spies += $int_min->spy_count if (defined($int_min));
    }
    if ($total_spies > $total_allowed_spies) {
        out($empire->name.' limited to '.$total_allowed_spies.' of '.$total_spies);
        my $count = 1;
        while (my $spy = $emp_spies->next) {
            if ($count++ > $total_allowed_spies) {
                $spy->update({
                              task => 'Debriefing',
                              defense_mission_count => 150,
                              available_on => DateTime->now->add(days => 14),
                             });
            }
        }
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


