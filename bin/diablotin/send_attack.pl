use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use AnyEvent;
$|=1;
our $quiet;
our $randomize;
GetOptions(
    'quiet'         => \$quiet,
    'randomize'         => \$randomize,
);


use Fcntl qw(:flock);
# stop multiple copies from running
unless (flock(DATA, LOCK_EX|LOCK_NB)) {
    print "$0 is already running. Exiting.\n";
    exit(1);
}


out('Started');
my $start = time;

#if ($randomize) {
#    sleep randint(0, 60*60*18); # attack anytime in the next 18 hours.
#}


out('Loading DB');
our $db = Lacuna->db;
our $ai = Lacuna::AI::Diablotin->new;

my $config = Lacuna->config;
my $cache = Lacuna->cache;

out('Looping through colonies...');
my $colonies = $ai->empire->planets;
my @attacks;
my @zones = Lacuna->db->resultset('Map::Star')->search(
        undef,
        { distinct => 1 }
    )->get_column('zone')->all;

while (my $attacking_colony = $colonies->next) {
    next if ($cache->get('diablotin_attack',$attacking_colony->id));
    out('Found colony to attack from named '.$attacking_colony->name);
    my @tzones = adjacent_zones($attacking_colony->zone, \@zones);
    out(sprintf("Find body to attack from %s into %s", $attacking_colony->zone, join(",",@tzones)));
    my $targets = $db->resultset('Lacuna::DB::Result::Map::Body')->search({
        empire_id                   => { '>' => 1 },
        'empire.is_isolationist'    => 0,
        zone => { 'in' => \@tzones },
    },
    {
        order_by    => 'rand()',
        rows        => 4,
        join        => 'empire',
    });
    my @ships = qw(bleeder thud placebo placebo2 placebo3);
    while (my $target_colony = $targets->next) {
        if ($target_colony->in_neutral_area) {
            out($target_colony->name." in Neutral Area, skipping.");
            next;
        }
        out('Attacking '.$target_colony->name);
        push @attacks, $ai->start_attack($attacking_colony, $target_colony, [shift @ships]);
    }
    my $rest = randint(48,72);
    $cache->set('diablotin_attack',$attacking_colony->id, 1, 60 * 60 * $rest);
}

out("Waiting on attacks...");
foreach my $attack (@attacks) {
    $attack->recv if defined $attack;
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");




###############
## SUBROUTINES
###############

sub adjacent_zones {
    my ($azone, $zones) = @_;

    my @tzones;
    my ($ax,$ay) = split('\|', $azone, 2);
    for my $x (0..2) {
        for my $y (0..2) {
            my $tzone = join("|",$x+$ax-1,$y+$ay-1);
            push @tzones, $tzone if (grep { $tzone eq $_ } @$zones);
        }
    }
    return @tzones;
}

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}

__DATA__
This exists so flock() code above works.
DO NOT REMOVE THIS DATA SECTION.
