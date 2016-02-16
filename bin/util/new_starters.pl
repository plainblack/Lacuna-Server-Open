# Setting more starter planets in the center zones. More likely, the closer to 0,0 the body is.
use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
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

out('Reviewing planets');
my $planets_rs = $db->resultset('Lacuna::DB::Result::Map::Body');
my @planets = $planets_rs->search( {
                                     empire_id   => undef,
                                     orbit       => {'!=' => 8},
                                     size        => {'>=' => 30},
                                     size        => {'<=' => 50},
                                   }
                       )->get_column('id')->all;
out('Found '.scalar @planets.' planets.');
my $old_s = 0; my $new_s = 0; my $unch = 0;
foreach my $id (@planets) {
    my $planet = $planets_rs->find($id);
    next unless ($planet->get_type eq 'habitable planet');
    next unless ($planet->zone ~~ ['1|1','1|-1','-1|1','-1|-1','0|0','0|1','1|0','-1|0','0|-1']);

    my $orbit = $planet->orbit;
    my $start_val = 80 - sqrt($planet->y**2 + $planet->x**2)/10;
    if ($orbit == 3) {
      $start_val = int(0.9 * $start_val);
    }
    elsif ($orbit == 4) {
      $start_val = int(0.7 * $start_val);
    }
    elsif ($orbit == 5 or $orbit == 6) {
      $start_val = int(0.6 * $start_val);
    }
    elsif ($orbit == 1 or $orbit == 7) {
      $start_val = int(0.4 * $start_val);
    }
    my $start_enb = (randint(0,99) < $start_val) ? 1 : 0;
    my $old_val = $planet->usable_as_starter;
    my $old_enb = $planet->usable_as_starter_enabled;

# If old start, then leave alone
    if ($old_enb) {
      $old_s++;
      out( sprintf("%30s OL:%4d-%d nv:%2d-%d o:%s (%4d,%4d) Z:%5s %s",
                 $planet->name,
                 $old_val, $old_enb,
                 $start_val, $start_enb,
                 $planet->orbit,
                 $planet->x, $planet->y,
                 $planet->zone,
                 $planet->get_type,
                 ));
    }
    elsif ($start_enb) {
      $new_s++;
      out( sprintf("%30s oo:%4d-%d NN:%2d-%d o:%s (%4d,%4d) Z:%5s %s",
                 $planet->name,
                 $old_val, $old_enb,
                 $start_val, $start_enb,
                 $planet->orbit,
                 $planet->x, $planet->y,
                 $planet->zone,
                 $planet->get_type,
                 ));
    }
    else {
      $unch++;
    }
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");
out(sprintf("%6d Planets checked, %6d added, %6d old, %6d unch", scalar @planets, $new_s, $old_s, $unch));


###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}
