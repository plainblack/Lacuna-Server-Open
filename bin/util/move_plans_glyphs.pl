use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
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
  our $from;
  our $to;
  our $move_p;
  our $move_g;

  GetOptions(
    'quiet'   => \$quiet,  
    'from=i'  => \$from,
    'to=i'    => \$to,
    'plans'   => \$move_p,
    'glyphs'  => \$move_g,
  );

  die "Must give from and to body ids\n" unless ($from and $to);
  die "to and from must be different!\n" if ($from == $to);
  die "Must give either define plans or glyphs to move\n" unless ($move_g or $move_p);
  out('Started');
  my $start = DateTime->now;

  out('Loading DB');
  our $db = Lacuna->db;

  my $body_from = $db->resultset('Map::Body')->find($from);
  my $body_dest = $db->resultset('Map::Body')->find($to);

  out(sprintf("%30s -> %30s", $body_from->name, $body_dest->name));

  my $glyphs = $body_from->glyph;
  my $plans  = $body_from->plan_cache;

  my $ptypes = 0;
  my $gtypes = 0;
  my $pquant = 0;
  my $gquant = 0;
  if ($move_p) {
      for my $plan (@{$plans}) {
          $ptypes++;
          $pquant += $plan->quantity;
          $body_dest->add_plan($plan->class, $plan->level, $plan->extra_build_level, $plan->quantity);
      }
      $body_from->_plans->delete;
  }
  if ($move_g) {
      while (my $glyph = $glyphs->next) {
          $gtypes++;
          $gquant += $glyph->quantity;
          $body_dest->add_glyph($glyph->type, $glyph->quantity);
      }
      $body_from->glyph->delete;
  }
  out(sprintf("Moved %3d/%5d plan t/q; Moved %3d/%5d glyph t/q", $ptypes, $pquant, $gtypes, $gquant));
exit;

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}
