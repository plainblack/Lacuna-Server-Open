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
our $body_id;
our $class;
our $count = 1;
our $level = 1;
our $extra = 0;
our $file;
our $verbose;

GetOptions(
    'quiet'    => \$quiet,  
    'body=i'   => \$body_id,
    'class=s'  => \$class,
    'level=i'  => \$level,
    'extra=i'  => \$extra,
    'count=i'  => \$count,
    'file=s'   => \$file,
    'verbose'  => \$verbose,
);

die "Usage: perl $0 body_id class count\n" unless (( defined $body_id && defined $class && defined $count ) or 
                                                   ( defined $body_id && defined $file));

out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

my $body = $db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
unless ($body) {
    die "Cannot find body id $body_id\n";
}

my $plans = [];
if ($file) {
    $plans = get_plans($file);
}
else {
    die "Cannot have extra level if base level is greater than 1!" if ($extra > 0 and $level > 1);
    $plans->[0]->{level} = $level;
    $plans->[0]->{extra} = $extra;
    $plans->[0]->{class} = $class;
    $plans->[0]->{quantity} = $count;
}

my $json = JSON->new->utf8(1);
print $json->pretty->canonical->encode($plans) if ($verbose);

for my $plan (@$plans) {
print $json->pretty->canonical->encode($plan) if ($verbose);
    say sprintf("Adding %d level %d+%d %s to %s:%d",
            $plan->{quantity}, $plan->{level}, $plan->{extra}, $plan->{class}, $body->name, $body->id);
    if ($plan->{extra} > 0 and $plan->{level} > 1) {
        say "Cannot have extra level if base level is greater than 1!";
        next;
    }
    $body->add_plan($plan->{class}, $plan->{level}, $plan->{extra}, $plan->{quantity});
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

sub get_plans {
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
