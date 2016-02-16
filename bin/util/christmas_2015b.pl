#!/data/apps/bin/perl

use strict;
use warnings;
use lib '/data/Lacuna-Server-Open/lib';
use L;
use List::Util qw(sum);
use Getopt::Long;

$|=1;
our $quiet;
GetOptions(
    'quiet' => \$quiet,
);

out('Started');
my $start = time;

my $bodies = LD->resultset('Map::Body')
    ->search(
             {
                 'me.notes' => { like => '%pyramid31%' },
                 '_plans.class' => 'Lacuna::DB::Result::Building::Permanent::PyramidJunkSculpture',
                 '_plans.level' => 31,
                 '_plans.extra_build_level' => 0,
                 '_plans.quantity' => { '>' => 0 },
                 '_buildings.class' => 'Lacuna::DB::Result::Building::Permanent::PyramidJunkSculpture',
                 '_buildings.level' => 30,
             },
             {
                 join => [ '_plans', '_buildings' ],
                 prefetch => [ 'empire' ],
             }
            );

my $santa = LD->empire('Santa Claus');

my $message = << 'MESSAGE';
Ho! Ho! Ho!

My elves have reported back to me that they found a request for a pyramid upgrade to level 31 on %s and have completed their work!

Now you can remove the magic word from the colony notes!

Merry Christmas!
MESSAGE

out('Looking for upgrades');
while (my $b = $bodies->next)
{
    out("Updating ". $b->name);

    my $pyr = $b->get_a_building('Permanent::PyramidJunkSculpture');
    die "What?" unless $pyr->level == 30;

    my $plan = $b->get_plan($pyr->class, 31);
    die "No plan??" unless $plan;

    $b->delete_one_plan($plan);
    $pyr->level(31); # no build time, Christmas magic
    $pyr->update;
    $b->needs_recalc(1);
    $b->needs_surface_refresh(1);
    $b->update;

    $b->empire->send_message(
        tag         => 'Correspondence',
        subject     => 'Elven magic.',
        from        => $santa,
        body        => sprintf($message,$b->name),
    );

}

