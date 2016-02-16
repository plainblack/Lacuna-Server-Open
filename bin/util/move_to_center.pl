use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use List::MoreUtils qw(uniq);
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);

# Fixups for after:
# update body set usable_as_starter=0, usable_as_starter_enabled=0 where orbit = 8;
# update body set usable_as_starter=10000 + floor(1 * (rand() * 500)) - abs(x) - abs(y) + size  where size >= 40 and size <= 50 and orbit <= 7;
# update body set usable_as_starter=usable_as_starter - 5000 where zone = '0|0' and usable_as_starter > 0;


out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
my $bodies = $db->resultset('Lacuna::DB::Result::Map::Body');
my $stars = $db->resultset('Lacuna::DB::Result::Map::Star');
my $empire = $db->resultset('Lacuna::DB::Result::Empire');

out('Figuring out which stars need to be moved...');
my @stars_to_move = $bodies->search({
        zone        => { 'not in' => ['0|0','1|0','1|1','0|1','-1|0','0|-1','1|-1','-1|1','-1|-1']},
        empire_id   => { '>' => 0 },
    },
    {
        order_by => 'empire_id'
    })
    ->get_column('star_id')
    ->all;
@stars_to_move = uniq(@stars_to_move);


out('Figuring out which stars can be displaced...');
my @stars_to_NOT_displace = $bodies->search({
        zone        => '0|0',
        empire_id   => { '>' => 0 },
    },
    {
        order_by => 'empire_id'
    })
    ->get_column('star_id')
    ->all;
@stars_to_NOT_displace = uniq(@stars_to_NOT_displace);
my @stars_in_zone = $stars->search({zone => '0|0'})->get_column('id')->all;
my @stars_to_displace;
foreach my $star (@stars_in_zone) {
    next if $star ~~ \@stars_to_NOT_displace;
    push @stars_to_displace, $star;
}

out('Moving stars...');
my $i = 0;
our %unique_empires;
foreach my $star_id (@stars_to_move) {
    $i++;
    my $star_to_move = $stars->find($star_id);
    pop @stars_to_displace; # put a little space between them
    my $star_to_displace = $stars->find(pop @stars_to_displace);
    say sprintf('#%s: Exchanging %s (%s,%s) with %s (%s,%s)', $i, $star_to_move->name, $star_to_move->x, $star_to_move->y, $star_to_displace->name, $star_to_displace->x, $star_to_displace->y);
    my $bodies = $star_to_move->bodies;
    while (my $body = $bodies->next) {
        move_body($body, $star_to_displace);
    }
    $bodies = $star_to_displace->bodies;
    while (my $body = $bodies->next) {
        move_body($body, $star_to_move);
    }
    my ($x, $y, $zone) = ($star_to_move->x, $star_to_move->y, $star_to_move->zone);
    say "\tMoving ".$star_to_move->name;
    $star_to_move->x($star_to_displace->x);
    $star_to_move->y($star_to_displace->y);
    $star_to_move->zone($star_to_displace->zone);
    $star_to_move->update;
    say "\tMoving ".$star_to_displace->name;
    $star_to_displace->x($x);
    $star_to_displace->y($y);
    $star_to_displace->zone($zone);
    $star_to_displace->update;
    say "\tUnique Empires: ".scalar(keys %unique_empires);
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");




###############
## SUBROUTINES
###############


sub move_body {
    my ($body, $star) = @_;
    say "\tMoving body ".$body->name;
    $unique_empires{$body->empire_id}=1 if ($body->empire_id);
    if ($body->orbit == 1) {
        $body->x($star->x + 1); $body->y($star->y + 2);
    }
    elsif ($body->orbit == 2) {
        $body->x($star->x + 2); $body->y($star->y + 1);
    }
    elsif ($body->orbit == 3) {
        $body->x($star->x + 2); $body->y($star->y - 1);
    }
    elsif ($body->orbit == 4) {
        $body->x($star->x + 1); $body->y($star->y - 2);
    }
    elsif ($body->orbit == 5) {
        $body->x($star->x - 1); $body->y($star->y - 2);
    }
    elsif ($body->orbit == 6) {
        $body->x($star->x - 2); $body->y($star->y - 1);
    }
    elsif ($body->orbit == 7) {
        $body->x($star->x - 2); $body->y($star->y + 1);
    }
    elsif ($body->orbit == 8) {
        $body->x($star->x - 1); $body->y($star->y + 2);
    }
    $body->zone($star->zone);
    $body->update;
}


sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


