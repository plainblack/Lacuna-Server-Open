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
GetOptions(
    'quiet'         => \$quiet,  
);

die "Not a good idea to run now."
# Worked well, except it didn't do anything with spy shuttles that were in orbit.

out('Started');
my $start = DateTime->now;

out('Loading DB');
our $db = Lacuna->db;
my $empires = $db->resultset('Lacuna::DB::Result::Empire');
my $bodies  = $db->resultset('Lacuna::DB::Result::Map::Body');

out('Withdrawing all spies in merc market');
my $merc_market = $db->resultset('Lacuna::DB::Result::MercenaryMarket')->search;
while (my $offer = $merc_market->next) {
    $offer->withdraw($offer->body);
}
my $now = DateTime->now;
my $spy_pods = $db->resultset('Lacuna::DB::Result::Ships')->search({type => 'spy_pod', task => 'Travelling'});
my %ship_involved;
while (my $pod = $spy_pods->next) {
    out('Zooming ship '.$pod->id);
    my $dest_id = $pod->foreign_body_id;
    my $from_id = $pod->body_id;
    $ship_involved{$dest_id} = 1 unless (defined($ship_involved{$dest_id}));
    $ship_involved{$from_id} = 1 unless (defined($ship_involved{$from_id}));
    $pod->update({
        date_available => $now,
    });
}
out('Tick of all planets that have spies going or coming via spy_pods.');
my $planets = $bodies->search({ empire_id   => {'!=' => 0} });
while (my $planet = $planets->next) {
    next unless $ship_involved{$planet->id};
    out('Ticking '.$planet->name);
    eval{$planet->tick};
    my $reason = $@;
    if (ref $reason eq 'ARRAY' && $reason->[0] eq -1) {
        # this is an expected exception, it means one of the roles took over
    }
    elsif ( ref $reason eq 'ARRAY') {
        out(sprintf("Ticking %s resulted in errno: %d, %s\n", $planet->name, $reason->[0], $reason->[1]));
    }
    elsif ( $reason ) {
        out(sprintf("Ticking %s resulted in: %s\n", $planet->name, $reason));
    }
}

my $spies   = $db->resultset('Lacuna::DB::Result::Spies');
out('Updating spy level');
while (my $spy = $spies->next) {
  if ($spy->task eq 'Captured') {
      $spy->delete;
      next;
  }
  my $xp_level = int(($spy->intel_xp + $spy->mayhem_xp + $spy->politics_xp + $spy->theft_xp)/200);
  $spy->level($xp_level);
  $spy->update;
}
out('Culling Spies');
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
    next unless $total_spies > 0;
    my $cull = $total_spies > $total_allowed_spies ? sprintf(" Culling %d spies", $total_spies - $total_allowed_spies) : '';
    out($empire->name.' limited to '.$total_allowed_spies.' of '.$total_spies.'.'.$cull);
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
                          available_on => DateTime->now->add(days => 30),
                         });
            for my $type (qw(intel mayhem politics theft)) {
                my $arg = "${type}_xp";
                $excess->{$type} += $spy->$arg;
                $spy->$arg(0);
            }
        }
        $spy->update;
    }
    my $kept_spies = $spies->search({empire_id=>$empire->id,
                                    task => {'!=' => 'Retiring'}},
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
        my $assign_id = $spy->on_body_id;
        if ($int_min_stat->{$home_id}->{cur_spies} < $int_min_stat->{$home_id}->{max_spies}) {
            $int_min_stat->{$home_id}->{cur_spies}++;
        }
        elsif (defined($int_min_stat->{$assign_id}) and
               ($int_min_stat->{$assign_id}->{cur_spies} < $int_min_stat->{$assign_id}->{max_spies})) {
            $int_min_stat->{$assign_id}->{cur_spies}++;
            $spy->from_body_id($assign_id);
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
    if ($excess->{intel} > 0 or
        $excess->{mayhem} > 0 or
        $excess->{politics} > 0 or
        $excess->{theft} > 0) {
        out(sprintf('%s : %d intel %d mayhem %d politics %d theft excess',
                    $empire->name, $excess->{intel},$excess->{mayhem},$excess->{politics},$excess->{theft}));
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


