use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
use Lacuna::AI::Trelvestian;
$|=1;
our $quiet;
our $add_one;
our $tournament;
our $test;
GetOptions(
    quiet           => \$quiet,
    addone          => \$add_one,
    tournament      => \$tournament,
    test	    => \$test,
);

out('Started');
my $start = time;

my $config = Lacuna->config;
my $server_url = $config->get('server_url');
say "Running on $server_url";

my $ai = Lacuna::AI::Trelvestian->new;

if ($tournament) {
    say 'Tournament mode';

    # for the side effect of running $ai->create_empire only if the empire hasn't been created yet
    my $colonies = $ai->empire->planets;

    my $viable = $ai->viable_colonies;
    my @colonies;

    if ($server_url =~ /us2/) {
        push @colonies, $viable->search({ x => { '>' => 150}, y => { '>' => 150} })->first;
        push @colonies, $viable->search({ x => { '<' => -150}, y => { '>' => 150} })->first;
        push @colonies, $viable->search({ x => { '<' => -150}, y => { '<' => -150} })->first;
        push @colonies, $viable->search({ x => { '>' => 150}, y => { '<' => -150} })->first;
    }
    elsif ($server_url =~ /us1/) {
        # four planets in 2|2
        my $search = {
            x => { -between => [ 500, 749 ] },
            y => { -between => [ 500, 749 ] },
        };
        push @colonies, $viable->search( $search, {rows=>4});

        if (@colonies) {
            say 'You need to add the colonies to ../etc/reboot.conf before the tournament begins.';
            my $list = join ',', map { $_->id } @colonies;
            say '"win" : { "alliance_control" : [' . $list . '] },'; # "win" : { "alliance_control" : [441,19093,47,19293] },
        }
    }
    else {
        say 'No information on ' . $server_url;
    }
    foreach my $body (@colonies) {
        if ($test) {
            say $body->name . ' ' . $body->x . ',' . $body->y;
        }
        else {
            say 'Clearing '.$body->name;
            $body->delete_buildings(@{$body->building_cache});
            say 'Colonizing '.$body->name;
            $body->found_colony($ai->empire);
            $ai->build_colony($body);
        }
    }
}
else {
    say 'Normal mode';
    if ($test) {
        say 'Would normally add colonies here';
    }
    else {
        $ai->add_colonies($add_one);
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

