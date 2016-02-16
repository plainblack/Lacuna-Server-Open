use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Data::Dumper;
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date random_element);
use Getopt::Long;
$|=1;
our $quiet;
our $number = 1;
our $target_zone;
our $target_body_id;

GetOptions(
    'quiet'         => \$quiet,  
    'number=i'        => \$number,
    'zone=s'          => \$target_zone,
    'body_id=i'        => \$target_body_id,
);

out("Putting ".$number." fissures in ".$target_zone." on ".$target_body_id.".");

my $search = {
  class      => { like => 'Lacuna::DB::Result::Map::Body::Planet::P%' },
};

if ($target_zone ne '') {
  $search->{zone} = $target_zone;
}
if ($target_body_id ne '') {
  $search->{id} = $target_body_id;
}
else {
  $search->{empire_id} = undef;
  usable_as_starter_enabled   => 0,
}

out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

my $placed = 0;
while ($placed < $number) {
  my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
                  $search,
                  { order_by => 'rand()' }
                )->first;
  unless (defined $target) {
    print "No body found\n";
    $placed++;
    next;
  }
  my $btype = $target->get_type;

  my ($throw, $reason) = check_bhg_neutralized($target);
  if ($throw > 0) {
    out($reason);
  }
  elsif ($btype eq 'habitable planet') {
    my ($x, $y) = eval { $target->find_free_space};
    unless ($@) {
        my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
            x            => $x,
            y            => $y,
            level        => randint(1, 30),
            body_id      => $target->id,
            body         => $target,
            class        => 'Lacuna::DB::Result::Building::Permanent::Fissure',
        });
        $target->build_building($building, undef, 1);
        out(sprintf('Level %s Fissure formed on %s:%s in zone %s.', $building->level, $target->id, $target->name, $target->zone ));
        $placed++;
    }
    else {
        out(sprintf('No fissure placed on %s.', $target->name));
    }
  }
  else {
    out(sprintf('No fissure placed on %s.', $target->name));
  }
}

exit;

sub check_bhg_neutralized {
  my ($check) = @_;
  my $tstar; my $tname;
  if (ref $check eq 'HASH') {
    $tstar = $check->{star};
    $tname = $check->{name};
  }
  else {
    if ($check->isa('Lacuna::DB::Result::Map::Star')) {
      $tstar   = $check;
      $tname   = $check->name;
    }
    else {
      $tstar   = $check->star;
      $tname   = $check->name;
    }
  }
  my $sname = $tstar->name;
  my $throw; my $reason;
  if ($tstar->station_id) {
    if ($tstar->station->laws->search({type => 'BHGNeutralized'})->count) {
      my $ss_name = $tstar->station->name;
      $throw = 1009;
      $reason = sprintf("The star, %s is under BHG Neutralization from %s", $sname, $ss_name),
      return $throw, $reason;
    }
  }
  return 0, "";
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

