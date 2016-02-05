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
our @body_id;
our $file;
our $verbose;

GetOptions(
    'quiet'    => \$quiet,  
    'bid=i@'   => \@body_id,
    'file=s'   => \$file,
    'verbose'  => \$verbose,
);

die "Usage: perl $0 body_id class count\n" unless (defined $file);

out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;


my $phash;
if ($file) {
    $phash = slurp($file);
}

if (scalar @body_id) {
  die "Only give bid arguments if there is one planet in plan file,\n" if (keys %$phash > 1);
}
else {
  @body_id = keys %$phash;
}

my $json = JSON->new->utf8(1);
say $json->pretty->canonical->encode($phash) if ($verbose);

for my $bid (sort @body_id) {
  my $body = $db->resultset('Lacuna::DB::Result::Map::Body')->find($bid);
  unless ($body) {
      say "Cannot find body id $bid : $phash->{$bid}->{name}\n";
      next;
  }
  my $cname = $body->name;
  if ($cname ne $phash->{$bid}->{name}) {
    say "Name mismatch between $cname and $phash->{$bid}->{name} : $bid\n";
    next;
  }
  say sprintf("Adding plans to %s : %d\n", $cname, $bid);
  my @plans = @{$phash->{$bid}->{mods}};
  for my $plan (@plans) {
    say $json->pretty->canonical->encode($plan) if ($verbose);
    say sprintf("    Adding %d level %d+%d %s to %s:%d",
            $plan->{quantity}, $plan->{level}, $plan->{extra}, $plan->{class}, $body->name, $body->id) if ($verbose);
    if ($plan->{extra} > 0 and $plan->{level} > 1) {
        say "Cannot have extra level if base level is greater than 1!";
        next;
    }
    $body->add_plan($plan->{class}, $plan->{level}, $plan->{extra}, $plan->{quantity});
  }
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}

sub slurp {
  my ( $data_file ) = @_;

  my $plan_data = get_json($data_file);
  unless ($plan_data) {
    die "Could not read $data_file\n";
  }
  return $plan_data;
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
