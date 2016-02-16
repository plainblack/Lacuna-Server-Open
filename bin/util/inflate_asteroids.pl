# Reinflate asteroids into planets
use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
our $target_zone;
our $target_body_id;
our $number = 10_000;

GetOptions(
    'zone=s'    => \$target_zone,
    'body_id=i' => \$target_body_id,
    'number=i'  => \$number,
    'quiet'     => \$quiet,  
);

die "$0 --zone ZONE --body_id BODYID --number NUMBER\n" unless $target_zone or $target_body_id;

out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

my $search = {
  class      => { like => 'Lacuna::DB::Result::Map::Body::Asteroid::%' },
};

if ($target_zone ne '') {
  $search->{zone} = $target_zone;
}
if ($target_body_id ne '') {
  $search->{id} = $target_body_id;
  $number = 1;
}

out('Reviewing asteroids');
my $rocks_rs = $db->resultset('Lacuna::DB::Result::Map::Body');
my @rocks = $rocks_rs->search(
                              $search,
                       )->get_column('id')->all;
out('Found '.scalar @rocks.' asteroids.');

my $changed = 0; my $unchanged = 0;
foreach my $id (sort { 5 > rand(10) } @rocks) {
    my $rock = $rocks_rs->find($id);
    next unless ($rock->get_type eq 'asteroid');

    my $orbit = $rock->orbit;

    my $new_t = randint(1,Lacuna::DB::Result::Map::Body->planet_types);
    my $class = 'Lacuna::DB::Result::Map::Body::Planet::P'.$new_t;
    my $size  = 30;
    my $old_class = $rock->class;
    $old_class =~ s/.*:://;
    my $pcount = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')
                ->search({asteroid_id => $id })->count;
    out( sprintf("%30s %6d %3s -> P%3s o:%s (%4d,%4d) Z:%5s %d",
                 $rock->name, $rock->id,
                 $old_class, $new_t,
                 $rock->orbit,
                 $rock->x, $rock->y,
                 $rock->zone,
                 $pcount,
                 ));
    if ($pcount) {
        $unchanged++;
    }
    else {
        $rock->size(45);
        $rock->class($class);
        if ($rock->orbit != 8) {
           $rock->usable_as_starter(randint(8000,9000) + 450 - abs($rock->y) - abs($rock->x));
           $rock->usable_as_starter_enabled(1);
        }
        $rock->update;
        $changed++;
    }
    if ($changed >= $number) {
        out("All done.");
        last;
    }
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");
out(sprintf("%6d Asteroids checked, %6d changed to planets, %6d unchanged", scalar @rocks, $changed, $unchanged));


###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}
