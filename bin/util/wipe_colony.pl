use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use JSON;
use utf8;
  $|=1;
  our $quiet;
  my @bid;
  my @eid;
  my $sanitize;

  binmode STDOUT, ":utf8";

  GetOptions(
    'quiet'    => \$quiet,  
    'body=s@'   => \@bid,
    'empire=s@' => \@eid,
    'sanitize' => \$sanitize,
  );


  die "Usage: perl $0 --body X or perl $0 --empire X\n" unless ( @bid|@eid);

  out('Started');
  my $start = time;

  out('Loading DB');
  our $db = Lacuna->db;

  if (@eid) {
      for my $eid (@eid) {
          my @bodies = map { $_->id } $db->resultset('Lacuna::DB::Result::Map::Body')->search({
                           empire_id => $eid,
                       });
          push @bid, @bodies;
      }
  }
  clean_off($sanitize, \@bid);
  out('Done');
exit;
###############
## SUBROUTINES
###############
sub clean_off {
  my ($sanitize, $bids) = @_;

  for my $bid (@$bids) {
      my $body = $db->resultset('Lacuna::DB::Result::Map::Body')->find($bid);
      unless ($body) {
          print "Cannot find body id $bid\n";
          next;
      }
      printf "Found %d, %s at %d/%d in zone %s owned by %d/%s. ", 
               $bid, $body->name, $body->x, $body->y, $body->zone,
               $body->empire_id ? $body->empire_id : 0,
               $body->empire_id ? $body->empire->name : "";
      if ($body->empire_id and $body->empire->home_planet_id == $bid) {
          print "Capitol, Skip\n";
          next;
      }
      if ($sanitize) {
          print "Clearing!\n";
      }
      else {
          print "Dry Run check.\n";
          next;
      }
      next if ($body->get_type eq 'asteroid');
      my @all_buildings = @{$body->building_cache};
      $body->delete_buildings(\@all_buildings);
      $body->sanitize;
  }
}

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
