use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use JSON;
$|=1;
our $quiet;
  my $body_id;
  my $bconfig;
  my $empire_id;

  GetOptions(
    'quiet'    => \$quiet,  
    'body=s'   => \$body_id,
    'bconfig=s' => \$bconfig,
    'empire_id=s' => \$empire_id,
  );


  die "Usage: perl $0 --empire_id X --body X\n" unless ( defined $body_id );

  out('Started');
  my $start = time;

  out('Loading DB');
  our $db = Lacuna->db;

  my $empires = $db->resultset('Lacuna::DB::Result::Empire');
  my $empire = $empires->find($empire_id);
  unless (defined($empire)) {
    die "Empire: $empire_id does not exist\n";
  }
  out (sprintf("Setting up for empire: %s:%s", $empire_id, $empire->name));

  my $body = $db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
  print "Found body!\n";
  unless ($body) {
    die "Cannot find body id $body_id\n";
  }
  if (defined($body->empire)) {
    out(sprintf("%s:%s is already occupied by %s:%s!\n", $body->id,$body->name, $empire->id, $empire->name));
    die;
  }
  if ($body->get_type ne "habitable planet") {
    $body->class('Lacuna::DB::Result::Map::Body::Planet::P1');
  }
  
  $body->convert_to_station($empire);
  print "Founded Station\n";
  $body->update;

  print $body->empire->name,"\n";
  my $beid = $body->empire->id;
  if ($beid != $empire_id) {
    my $name = $body->name;
    die "$name belongs to $beid\n";
  }

  my @current_buildings = @{$body->building_cache};
  $body->delete_buildings(\@current_buildings);

  my $builds = get_builds($bconfig);

  say "Adding to ".$body->name;
  for my $build (@$builds) {
    next if ($build->{level} < 1 or $build->{level} > 30);
    my $bld = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        body_id  => $body->id,
        x        => $build->{x},
        y        => $build->{y},
        class    => $build->{class},
        level    => $build->{level} - 1,
     });
     say sprintf("%2d:%2d L:%2d %s", $bld->x, $bld->y, $bld->level, $bld->name);
     $body->build_building($bld);
     $bld->finish_upgrade;
  }
  $body->needs_surface_refresh(1);
  $body->needs_recalc(1);
  $body->update;
  $body->tick;
  $body->energy_stored($body->energy_capacity);
  $body->water_stored($body->water_capacity);
  $body->pie_stored($body->food_capacity);
  $body->magnetite_stored($body->ore_capacity);
  $body->needs_surface_refresh(1);
  $body->needs_recalc(1);
  $body->update;

  my $finish = time;
  out('Finished');
  out((($finish - $start)/60)." minutes have elapsed");
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

sub get_builds {
  my ( $data_file ) = @_;

  my $bld_data = get_json($data_file);
  unless ($bld_data) {
    die "Could not read $data_file\n";
  }
  return $bld_data;
}

sub get_json {
  my ($file) = @_;

  if (-e $file) {
    my $json = JSON->new->utf8(1);
    my $fh; my $lines;
    open($fh, "$file") || die "Could not open $file\n";
    $lines = join("", <$fh>);
    my $data = $json->decode($lines);
    close($fh);
    return $data;
  }
  else {
    warn "$file not found!\n";
  }
  return 0;
}
