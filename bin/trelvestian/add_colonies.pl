use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
use Lacuna::AI::Trelvestian;
$|=1;
our $quiet;
our $add_one;
our $tournament;
GetOptions(
    quiet           => \$quiet,
    addone          => \$add_one,
    tournament      => \$tournament,
);



out('Started');
my $start = time;

my $config = Lacuna->config;
my $server_url = $config->get('server_url');
say "Running on $server_url";

my $ai = Lacuna::AI::Trelvestian->new;

if ($tournament) {
    say 'Tournament mode';

    $ai->create_empire;
    my $viable = $ai->viable_colonies;
    my @colonies;

    my $test = 0; # BUG

    if ($server_url =~ /us2/) {
        push @colonies, $viable->search({ x => { '>' => 150}, y => { '>' => 150} },{rows=>1})->single;
        push @colonies, $viable->search({ x => { '<' => -150}, y => { '>' => 150} },{rows=>1})->single;
        push @colonies, $viable->search({ x => { '<' => -150}, y => { '<' => -150} },{rows=>1})->single;
        push @colonies, $viable->search({ x => { '>' => 150}, y => { '<' => -150} },{rows=>1})->single;
    }
    elsif ($server_url =~ /us1/) {
        # four planets in 2|2
        my $search = {
            x => { -between => [ 500, 749 ] },
            y => { -between => [ 500, 749 ] },
        };
        push @colonies, $viable->search( $search, {rows=>1})->single;
        push @colonies, $viable->search( $search, {rows=>1})->single;
        push @colonies, $viable->search( $search, {rows=>1})->single;
        push @colonies, $viable->search( $search, {rows=>1})->single;

        say 'You need to add the colonies to ../etc/lacuna.conf before the tournament begins.';
        say '"win" : { "alliance_control" : [' . join(',', @colonies) . '] },'; # "win" : { "alliance_control" : [441,19093,47,19293] },

        $test = 1; # BUG
    }
    else {
        say 'No information on ' . $server_url;
    }
    foreach my $body (@colonies) {
        say 'Clearing '.$body->name;
        unless ( $test ) {
            $body->buildings->delete_all;
            say 'Colonizing '.$body->name;
            $body->found_colony($ai->empire);
            $ai->build_colony($body);
        }
        else {
            say $body->x . ',' . $body->y;
        }
    }
}
else {
    say 'Normal mode';

    $ai->add_colonies($add_one);
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


