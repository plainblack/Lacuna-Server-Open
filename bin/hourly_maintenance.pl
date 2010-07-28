use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint format_date to_seconds);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);


out('Started');
my $start = DateTime->now;

out('Loading DB');
our $db = Lacuna->db;
my $empires = $db->resultset('Lacuna::DB::Result::Empire');


out('Deleting dead spies');
$db->resultset('Lacuna::DB::Result::Spies')->search({task=>'Killed In Action'})->delete_all;

out('Deleting Expired Self Destruct Empires');
$empires->search({ self_destruct_date => { '<' => $start }, self_destruct_active => 1})->delete_all;

out('Enabling Self Destruct For Inactivity');
my $inactives = $empires->search({ last_login => { '<' => DateTime->now->subtract( days => 15 ) }, self_destruct_active => 0, id => { '>' => 1}});
while (my $empire = $inactives->next) {
    out('Enabling self destruct on '.$empire->name);
    $empire->enable_self_destruct;
}

out('Ticking planets');
my $planets = $db->resultset('Lacuna::DB::Result::Map::Body')->search({ empire_id   => {'>' => 0} });
while (my $planet = $planets->next) {
    out('Ticking '.$planet->name);
    $planet->tick;
}

my $finish = DateTime->now;
out('Finished');
out((to_seconds($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


