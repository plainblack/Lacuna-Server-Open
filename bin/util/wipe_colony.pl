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
  my @body_id;
  my $sanitize;

  GetOptions(
    'quiet'    => \$quiet,  
    'body=s@'   => \@body_id,
  );


  die "Usage: perl $0 --body X\n" unless ( @body_id );

  out('Started');
  my $start = time;

  out('Loading DB');
  our $db = Lacuna->db;

  for my $body_id (@body_id) {
    my $body = $db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
    printf "Found %d, %s at %d/%d in zone %s\n", $body_id, $body->name, $body->x, $body->y, $body->zone;
    unless ($body) {
      print "Cannot find body id $body_id\n";
      next;
    }
    next if ($body->get_type eq 'asteroid');
    my @all_buildings = @{$body->building_cache};
    $body->delete_buildings(\@all_buildings);
    $body->sanitize;
  }
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
