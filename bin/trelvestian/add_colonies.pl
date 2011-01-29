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

my $ai = Lacuna::AI::Trelvestian->new;

if ($tournament) {
    $ai->create_empire;
    my $viable = $ai->viable_colonies;
    my @colonies;
    push @colonies, $viable->search({ x => { '>' => 150}, y => { '>' => 150} },{rows=>1})->single;
    push @colonies, $viable->search({ x => { '<' => -150}, y => { '>' => 150} },{rows=>1})->single;
    push @colonies, $viable->search({ x => { '<' => -150}, y => { '<' => -150} },{rows=>1})->single;
    push @colonies, $viable->search({ x => { '>' => 150}, y => { '<' => -150} },{rows=>1})->single;
    foreach my $body (@colonies) {
        say 'Clearing '.$body->name;
        $body->buildings->delete_all;
        say 'Colonizing '.$body->name;
        $body->found_colony($ai->empire);
        $ai->build_colony($body);
    }
}
else {
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


