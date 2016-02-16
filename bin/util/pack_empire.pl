use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
use DateTime;
use JSON;
$|=1;
  our $quiet;
  my $capitol;
  my $config;
  my $empire_id;
  my $sanitize;
  my $output;
  my $station;
  my $json = JSON->new->utf8(1);

  GetOptions(
    'quiet'    => \$quiet,  
    'empire_id=s' => \$empire_id,
    'capitol=s'   => \$capitol,
    'output=s'    => \$output,
    'station'     => \$station,
  );


  die "Usage: perl $0 --empire_id X\n" unless ( defined $empire_id );

  out('Started');
  my $start = time;
  my $dtf = Lacuna->db->storage->datetime_parser;

  out('Loading DB');
  our $db = Lacuna->db;

  my $empires = $db->resultset('Lacuna::DB::Result::Empire');
  my $empire = $empires->find($empire_id);
  die "Could not find Empire!\n" unless $empire;
  print "Setting up for empire: ".$empire->name." : ".$empire_id."\n";
  my $ehash;
  my $cap;
  if ($capitol) {
      $cap = $db->resultset('Lacuna::DB::Result::Map::Body')->find($capitol);
  }
  else {
      $cap = $db->resultset('Lacuna::DB::Result::Map::Body')->find($empire->home_planet_id);
  }
  unless ($cap) {
      die "Cannot find capitol $capitol\n";
  }
  if ($cap->empire_id != $empire->id) {
      die "Empire does not match capitol for empire!\n";
  }
  unless ($output) {
      $output = "pack_".$empire_id.".js";
  }
  my $df;
  open($df, ">", "$output") or die "Could not open $output for writing.\n";
  $ehash->{empire} = {
      name => $empire->name,
      id   => $empire->id,
      date_created => $dtf->format_datetime($empire->date_created),
      archive_date => $dtf->format_datetime(DateTime->now),
      essentia => $empire->essentia_paid + $empire->essentia_game +$empire->essentia_free,
  };
  my %plan_h;
  my %glyph_h;
  my $bodies = Lacuna->db
                     ->resultset('Lacuna::DB::Result::Map::Body')->search({
                         empire_id => $empire->id,
                     });
  my $count = 0;
  my @bodies;
  while (my $body = $bodies->next) {
      next if (!$station and ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')));
      my %builds;
      $count++;
      print "Packing ".$body->name.":";
      my $body_h = {
          id        => $body->id,
          happiness => $body->happiness,
          name      => $body->name,
          class     => $body->class,
          x         => $body->x,
          y         => $body->y,
          orbit     => $body->orbit,
          zone      => $body->zone,
          is_cap    => $cap->id == $body->id ? 1 : 0,
      };
      print "Building:";
      my $buildings = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search({body_id => $body->id});
      my @blds;
      while (my $bld = $buildings->next) {
#Treat Essentia_veins different? Drain and destroy?
          my $bld_h = {
              date_created => $dtf->format_datetime($bld->date_created),
              x            => $bld->x,
              y            => $bld->y,
              class => $bld->class,
              level => $bld->level,
          };
          push @blds, $bld_h;
      }
      $body_h->{building} = \@blds;
      print "Plans:";
      my @plans = @{$body->plan_cache};
      for my $plan (@plans) {
          my $key = join(":",$plan->class,$plan->level,$plan->extra_build_level);
          if ($plan_h{$key}) {
              $plan_h{$key}->{quantity} += $plan->quantity;
          }
          else {
              $plan_h{$key} = {
                  quantity => $plan->quantity,
                  class => $plan->class,
                  level => $plan->level,
                  extra_build_level => $plan->extra_build_level,
              };
          }
      }
      print "Glyphs:";
      my $glyphs = Lacuna->db->resultset('Lacuna::DB::Result::Glyph')->search({body_id => $body->id});
      while (my $glyph = $glyphs->next) {
          if ($glyph_h{$glyph->type}) {
              $glyph_h{$glyph->type}->{quantity} += $glyph->quantity;
          }
          else {
              $glyph_h{$glyph->type} = {
                  quantity => $glyph->quantity,
                  type     => $glyph->type,
              };
          }
      }
      push @bodies, $body_h;
      print "done\n";
  }
  $ehash->{body} = \@bodies;
  $ehash->{plan} = \%plan_h;
  $ehash->{glyph} = \%glyph_h;

  print $df $json->pretty->canonical->encode($ehash);
  my $finish = time;
  out($count.' Planets packed');
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
