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

# Going to redo the level calc to account for training, more than base.
my $spies   = $db->resultset('Lacuna::DB::Result::Spies');
out('Updating spy level');
while (my $spy = $spies->next) {
  my $xp_level = int(($spy->intel_xp + $spy->mayhem_xp + $spy->politics_xp + $spy->theft_xp)/200);
  $spy->level($xp_level);
  $spy->update;
}
out('wee!');
$spies   = $db->resultset('Lacuna::DB::Result::Spies');

while (my $empire = $empires->next) {
    next if $empire->id < 2;
    my $emp_spies = $spies->search({empire_id=>$empire->id}, {order_by => { -desc => 'level'}});
    my $emp_bodies = $bodies->search({empire_id=>$empire->id});
    my $total_allowed_spies = 0;
    my $total_spies = 0;
    my $int_min_stat = {};
    while (my $body = $emp_bodies->next) {
        my $bid = $body->id;
        my $int_min = $body->get_building_of_class('Lacuna::DB::Result::Building::Intelligence');
        if (defined($int_min)) {
            $total_allowed_spies += $int_min->max_spies;
            $total_spies += $int_min->spy_count;
            $int_min_stat->{$bid} = {
                max_spies => $int_min->max_spies,
                cur_spies => 0,
            };
        }
    }
    out($empire->name.' limited to '.$total_allowed_spies.' of '.$total_spies);
    my $excess = {
         intel => 0,
         mayhem => 0,
         politics => 0,
         theft => 0,
    };
    my $count = 0;
    while (my $spy = $emp_spies->next) {
        if ($count++ < $total_allowed_spies) {
            my $tot_excess = 0;
            my @spread;
            for my $type (qw(intel mayhem politics theft)) {
                my $arg = "${type}_xp";
                if ($spy->$arg > 2600) {
                    $tot_excess += ($spy->$arg - 2600);
                    $spy->$arg(2600);
                }
                else {
                  push @spread, $type;
                }
            }
            if ($tot_excess > 0) {
                my $extra;
                if (scalar @spread) {
                    my %room;
                    my $tot_room = 0;
                    for my $type (@spread) {
                        my $arg = "${type}_xp";
                        $room{$type} = 2600 - $spy->$arg;
                        $tot_room += $room{$type};
                    }
                    if ($tot_room > $tot_excess) {
                        my $extra = int($tot_excess/scalar @spread)+1;
                        $tot_excess = 0;
                        for my $type (@spread) {
                            my $arg = "${type}_xp";
                            my $total = $spy->$arg + $extra;
                            if ($total > 2600) {
                                $tot_excess += $total - 2600;
                                $total = 2600;
                            }
                            $spy->$arg($total);
                        }
                    }
                    else {
                        $tot_excess -= $tot_room;
                        for my $type (@spread) {
                            my $arg = "${type}_xp";
                            $spy->$arg(2600);
                        }
                    }
                }
                if ($tot_excess) {
                    for my $type (qw(intel mayhem politics theft)) {
                        $excess->{$type} += int($tot_excess/4)+1;
                    }
                }
            }
        }
        else {
            $spy->update({
                          task => 'Retiring',
#                          defense_mission_count => 150,
                          available_on => DateTime->now->add(days => 14),
                         });
            for my $type (qw(intel mayhem politics theft)) {
                my $arg = "${type}_xp";
                $excess->{$type} += $spy->$arg;
                $spy->$arg(0);
            }
        }
        $spy->update;
    }
    my $kept_spies = $spies->search({empire_id=>$empire->id},
                                    {task => {'!=' => 'Retiring'}},
                                    {order_by => { -desc => 'level'}});
    while (my $spy = $kept_spies->next) {
        $spy->offense_mission_count(0);
        $spy->defense_mission_count(0);
        for my $type (qw(intel mayhem politics theft)) {
            my $arg = "${type}_xp";
            next unless ($excess->{$type} > 0);
            my $curxp = $spy->$arg;
            my $room = 2600 - $curxp;
            next unless $room > 0;
            $room = $room > $excess->{$type} ? $excess->{$type} : $room;
            $excess->{$type} -= $room;
            $spy->$arg($room + $curxp);
        }
        my $home_id = $spy->from_body_id;
        if ($int_min_stat->{$home_id}->{cur_spies} < $int_min_stat->{$home_id}->{max_spies}) {
            $int_min_stat->{$home_id}->{cur_spies}++;
        }
        else {
            for my $bid (keys %{$int_min_stat}) {
                if ($int_min_stat->{$bid}->{cur_spies} < $int_min_stat->{$bid}->{max_spies}) {
                    $int_min_stat->{$bid}->{cur_spies}++;
                    $spy->from_body_id($bid);
                    last;
                }
            }
        }
        $spy->on_body_id($spy->from_body_id);
        
        $spy->update_level;
        $spy->update;
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


