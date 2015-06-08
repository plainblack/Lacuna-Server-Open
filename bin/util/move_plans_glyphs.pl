use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use L;
use Getopt::Long;
use utf8;


  $|=1;

  our $from;
  our $to;
  our $move_p;
  our $move_g;

  GetOptions(
    'quiet|q'   => \$quiet,  
    'from|f=s'  => \$from,
    'to|t=s'    => \$to,
    'plans|p'   => \$move_p,
    'glyphs|g'  => \$move_g,
  );

  die "Must give from and to body ids\n" unless ($from and $to);
  die "Must give either define plans or glyphs to move\n" unless ($move_g or $move_p);
  out('Started');
  my $start = DateTime->now;

  out('Loading DB');
  our $db = Lacuna->db;

  my $body_from = $db->body($from);
  my $body_dest = $db->body($to);
  die "to and from must be different!\n" if ($body_from->id == $body_dest->id);

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

