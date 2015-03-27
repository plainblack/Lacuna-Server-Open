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
  my $config;
  my $empire_id;
  my $sanitize;

  GetOptions(
    'quiet'    => \$quiet,  
    'body=s'   => \$body_id,
    'config=s' => \$config,
    'empire_id=s' => \$empire_id,
    'sanitize'  => \$sanitize,
  );


  die "Usage: perl $0 --empire_id X --body X\n" unless ( defined $body_id );

  out('Started');
  my $start = time;

  out('Loading DB');
  our $db = Lacuna->db;

  my $empires = $db->resultset('Lacuna::DB::Result::Empire');
  my $empire = $empires->find($empire_id);
  print "Setting up for empire: $empire->name : $empire_id\n";

  my $body = $db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
  print "Found body!\n";
  unless ($body) {
    die "Cannot find body id $body_id\n";
  }
  print "Really!\n";
  if ($sanitize) {
    my @all_buildings = @{$body->building_cache};
    $body->delete_buildings(\@all_buildings);
    $body->sanitize;
  }
  print "Checking empire\n";
  unless (defined($body->empire)) {
    $body->found_colony($empire);
  }
  print "Founded Colony\n";
  print $body->empire->name,"\n";
  my $beid = $body->empire->id;
  if ($beid != $empire_id) {
    my $name = $body->name;
    die "$name belongs to $beid\n";
  }

  my $builds = get_builds($config);

  say "Adding to ".$body->name;
  for my $build (@$builds) {
    next if ($build->{level} < 1 or $build->{level} > 30);
#    my ($x, $y) = $body->find_free_space;
#    next if $y > -1;
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
