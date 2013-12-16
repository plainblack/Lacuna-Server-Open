use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Data::Dumper;
use DateTime;
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date random_element);
use List::Util 'shuffle';
use Getopt::Long;
$|=1;
our $quiet;
our $turn_spy = 1;
our $run_mission = 1;
our $place_fissure = 1;

my $ok = GetOptions(
    'quiet'              => \$quiet,  
);

unless ($ok) {
  die "$0\n";
}

# Method

# 1) Get all worlds with a BHG, not AI owned, not in NZ
# 2) Create a high level Saben on each, set to "BHG Sabotage"

out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

my $saben =  $db->resultset('Empire')->find(-1);

die "Saben not setup as an empire!\n" unless defined($saben);

out("");

# Find planets with BHG
my $dtf = $db->storage->datetime_parser;
my %has_bhg = map { $_->body_id => 1 } $db->resultset('Building')->search({
     class => 'Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator',
     })->all;

my $num_body = scalar keys %has_bhg;
out('');
out('Ticking '.$num_body.' bodies that have BHG.');

for my $body_id (sort keys %has_bhg) {
    my $body = $db->resultset('Map::Body')->find($body_id);
    unless ( defined($body->empire_id) ) {
        out( $body->name.' is unoccupied.');
        next;
    }
    unless ($body->empire_id > 1) {
        out( $body->name.' is an AI planet.');
        next;
    }
    if ($body->in_neutral_area) {
        out( $body->name.' is in the neutral zone.');
        next;
    }

    my @bhgs = $body->get_buildings_of_class('Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator');

    unless (scalar @bhgs) {
        out('How did we lose the bhg already?');
        next;
    }
    my $elevel = $body->empire->university_level;
    my $spy = $db->resultset('Spies')->new({
           from_body_id    => $saben->home_planet_id,
           on_body_id      => $body_id,
           task            => 'Sabotage BHG',
           started_assignment  => DateTime->now,
           available_on    => DateTime->now,
           empire_id       => $saben->id,
           offense         => 2600,
           defense         => 250,
           mayhem_xp       => 80*$elevel+200,
           intel_xp        => 80*$elevel+200,
           name            => 'Agent BHG',
        })
        ->update_level
        ->insert;
    out('Placed '.$spy->id.' on '.$body->name);
}

out('Finished');
exit;

###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}

sub commify {
  local $_  = shift;
  1 while s/^(-?\d+)(\d{3})/$1,$2/;
  return $_;
}

sub nformat {
    my $entry  = shift;

    my $zeros = length(abs($entry))-1;

    my $num;
    my $init;
    if ($zeros < 9) {
        $init = 'M'; 
        $num = sprintf("%6.2f", $entry/1_000_000);
    }
    elsif ($zeros < 12) {
        $init = 'B'; 
        $num = sprintf("%6.2f", $entry/1_000_000_000);
    }
    elsif ($zeros < 15) {
        $init = 'T'; 
        $num = sprintf("%6.2f", $entry/1_000_000_000_000);
    }
    else {
        $init = 'Q'; 
        $num = sprintf("%6.2f", $entry/1_000_000_000_000_000);
    }
  
    return sprintf("%6s%s",$num,$init);
}

sub fzone {
    my $zone = shift;

    my ($x,$y) = split('|', $zone, 2);

    return sprintf("%2d|%2d", $x, $y);
}
