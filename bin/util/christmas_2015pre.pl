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

my $empires = LD->resultset('Empire')
    ->search(
             { 
                 'notes' => { like => '%happy%' },
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
Santa's elves here.  We've been helping Santa with his Christmas list this year, and have noticed that your Christmas wish may be misunderstood.

When Santa comes along, he'll be in a great hurry, so if your empire notes don't match exactly, he'll end up leaving your presents in the wrong place.

Your empire notes have the word "happy" in there, but do not exactly match the required format to help speed Santa's delivery with accuracy.

The format must look like this:

"happy: your planet"

or

"happy: your planet body ID"

The quotes, and their positioning around the whole request, are important, or Santa won't find them.

In your case, %s

Tou Ra Ell
Elf In Charge of TLE Gift Targetting

PS: If you have the word "happy" in your notes and don't intend on it being part of this Christmas' event, please accept my apologies - we have so much expanse to review, it's too easy to misread requests.

PPS: No, I am not related to Tou Re Ell.  I think I got this job only because Santa was being funny and noticed the name similarity.
MESSAGE

out('Finding empires');
while (my $e = $empires->next)
{
    out("Checking ". $e->name);
    next;
    my $notes = $e->notes;
    my $error;

    my $find_happy = qr/" \s*
        happy \s* : \s*
        ([^"]*?) \s*
        "/xi;  # i = some people may have capitalised something.

    if ($notes =~ $find_happy)
    {
        # $1 is somehow magical - stringify to lose said magic.
        my $request = "$1";
        out("  User requested '$request'.");
        my $happy = LD->body($request);
        if (!$happy) {
            if ($request =~ /\D/) {
                $error = "we cannot find '$request' as a target planet.";
            } else {
                $error = "we cannot find '$request' as a target planet ID (be sure you get the planet ID, not an ID for a building on the planet).";
            }
        }
        elsif ($happy->get_type eq 'space station') {
            $error = "we cannot target a space station.";
        }
        elsif ($happy->empire_id != $e->id) {
            $error = "'$request' is not your planet";
        }
    }
    else
    {
        $error = "format not followed.";
    }

    if ($error) {
        out($error);

        $e->send_message(
            tag         => 'Correspondence',
            subject     => 'Error detected in empire notes.',
            from        => $santa,
            body        => sprintf($message,$error),
        );
    }

}

