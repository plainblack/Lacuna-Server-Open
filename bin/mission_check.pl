use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
use JSON;
use SOAP::Amazon::S3;
use Lacuna::Constants qw(SHIP_TYPES ORE_TYPES);
use utf8;


  $|=1;

  our $quiet;
  our $empire_id;
  our $zone;
  our $level = 0;
  our $show = 0;

  GetOptions(
      'quiet'        => \$quiet,  
      'empire_id=i'  => \$empire_id,
      'zone=s'       => \$zone,
      'level=i'      => \$level,
      'show'         => \$show,
  );

  die "Must give empire_id\n" unless ($empire_id);
  out('Started');
  my $start = DateTime->now;

  out('Loading DB');
  our $db = Lacuna->db;

  my $emp = $db->resultset('Empire')->find($empire_id);

  die "No empire with id:$empire_id found\n" unless $emp;

  my $missions;
  if ($zone) {
      $missions = Lacuna->db->resultset('Lacuna::DB::Result::Mission')->search({
          zone                    => $zone,
      });
  }
  else {
      $missions = Lacuna->db->resultset('Lacuna::DB::Result::Mission');
  }
  my %mission_name;

  while ( my $mission = $missions->next) {
      unless ($mission_name{$mission->mission_file_name}) {
          $mission_name{$mission->mission_file_name} = 1;
          my $done = 0;
          $done = 1 if Lacuna->cache->get($mission->mission_file_name, $empire_id);
          next if ($mission->max_university_level < $level);
          next if ($done == 1 and !$show);
          out(sprintf("%40s %2d %5s %1d",
              $mission->mission_file_name,
              $mission->max_university_level,
              $mission->zone,
              $done));
      }
  }

exit;

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}
