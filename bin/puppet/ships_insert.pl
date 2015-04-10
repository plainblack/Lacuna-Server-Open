use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use JSON;
use utf8;


  $|=1;

  our $quiet;
  our $config;
  our $fill;
  our $maintain;

  my $ok = GetOptions(
      'config=s'  => \$config,
      'fill'  => \$fill,
      'maintain'  => \$maintain,
  );
  die "$0 --fill --maintain --config CFGFILE\n" unless $ok;

  die "Must give config\n" unless ($config);
  out('Started');
  my $start = DateTime->now;

  out('Loading DB');
  my $builds = get_ships($config);

  for my $body_name (sort keys %$builds) {
      my $body = Lacuna->db->resultset('Map::Body')->search( { name => "$body_name" })->first;
      unless ($body) {
          out("Could not find $body_name");
          next;
      }
      for my $shash (@{$builds->{$body_name}}) {
          my $to_build = $shash->{number};
          if ($maintain) {
              my $current = Lacuna->db->resultset('Ships')->search({ body_id => $body->id, type => $shash->{type} })->count;
              $to_build -= $current;
              $to_build = 0 if $to_build < 0;
          }
          if ($fill and $to_build > $body->spaceport->docks_available) {
              $to_build = $body->spaceport->docks_available;
          }
          printf "Adding %s of %s %s to %s\n", $to_build, $shash->{number}, $shash->{type}, $body_name;
          for (1..$to_build) {
              my $berth_level = $shash->{berth_level} ? $shash->{berth_level} : 1;
              my $new = $body->ships->new({
                  type            => $shash->{type},
                  name            => $shash->{name},
                  shipyard_id     => "552",
                  speed           => $shash->{speed},
                  combat          => $shash->{combat},
                  stealth         => $shash->{stealth},
                  hold_size       => $shash->{hold_size},
                  berth_level     => $berth_level,
                  date_available  => DateTime->now,
                  date_started    => DateTime->now,
                  body_id         => $body->id,
                  task            => 'Docked',
                                         })->insert;
          }
      }
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

sub get_ships {
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
