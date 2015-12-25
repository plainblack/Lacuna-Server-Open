#!/data/apps/bin/perl

use strict;
use warnings;
use lib '/data/Lacuna-Server/lib';
use L;
use List::Util qw(sum);
use Getopt::Long;

LD->class('Empire')->has_many('selflogins', 'Lacuna::DB::Result::Log::Login', sub {
    my $args = shift;
    return (
            {
                "$args->{foreign_alias}.empire_id" => { -ident => "$args->{self_alias}.id" },
                "$args->{foreign_alias}.is_sitter" => 0,
            },
            $args->{self_rowobj} && {
                "$args->foreign_alias}.empire_id" => $args->{self_rowobj}->id,
                "$args->{foreign_alias}.is_sitter" => 0,
            }
           )
});

# this is a hack shown to me on IRC in #dbix-class for reregistering
# a DBIC class after having modified the relationships at runtime
# as per above.
my $rec_class = LD->class('Empire');
LD->unregister_source('Empire');
LD->register_class('Empire' => $rec_class);


$|=1;
our $quiet;
GetOptions(
    'quiet' => \$quiet,
);

out('Started');
my $start = time;

# this will take ~45 seconds to query, but we're only running it once.
my $empires = LD->resultset('Empire')
    ->search(
             { 
                 'me.id' => { '>' => 1 },
                 'selflogins.date_stamp' => { '>=' => '2015-12-01 00:00:00' },
             },
             {
                 join => 'selflogins',
                 group_by => 'me.id',
             }
            );

my $santa = LD->empire('Santa Claus');

my $message = << 'MESSAGE';
Ho! Ho! Ho!

It appears that the Christmas spirit has infected %s, the whole planet is so much happier now!

It might just have something to do with that new plan left behind.  Though you may not be able to build it, my elves will keep an eye out for when you're ready.  All you have to do is move the plan to your desired colony, go into the Planetary Command Center's Notes tab, and put the magic word "pyramid31" in, save it, and the next time the elves notice, it will be done!

But, beware the Ides of March - if the plan isn't used by March 15th, it will disappear!  Be sure to use it!
MESSAGE

out('Sending messages');
while (my $e = $empires->next)
{
    out("Updating ". $e->name);
    my $home = $e->home_planet;
    next unless defined $home;

    my $notes = $e->notes;
    my $target = $home;

    my $find_happy = qr/" \s*
        happy \s* : \s*
        ([^"]*?) \s*
        "/xi;  # i = some people may have capitalised something.

    if (
        defined $notes && length $notes &&
        $notes =~ $find_happy)
    {
        # $1 is somehow magical - stringify to lose said magic.
        my $request = "$1";
        out("  User requested planet '$request'.");
        my $happy = LD->body($request);
        if ($happy &&
            $happy->empire_id == $e->id &&
            $happy->get_type  ne 'space station'
           )
        {
            # found it, keep it.
            out("  " . $happy->name . " is owned by empire " . $e->name . ", using it and marking it done in empire notes.");

            $notes =~ s/$find_happy\K/ -- DONE/;

            $e->notes($notes);
            $e->update;
            $target = $happy;
        }
    }

    out("  Planet: ".$target->name);

    # give out 3Q happy
    my $happy_bonus = 3e15;

    # but if the target is already 3Q in the hole, bring them to zero.
    $happy_bonus = -$target->happiness if $target->happiness < -$happy_bonus;

    out("   happy + $happy_bonus");
    $target->add_happiness($happy_bonus);
    $target->update;

    out("   Pyramid 31+0");
    $target->add_plan('Lacuna::DB::Result::Building::Permanent::PyramidJunkSculpture',31,0,1);

    $e->send_message(
        tag         => 'Correspondence',
        subject     => 'A Gift.',
        from        => $santa,
        body        => sprintf($message,$target->name),
    );

}

