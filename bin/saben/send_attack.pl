use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,
);



out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
our $empires = $db->resultset('Lacuna::DB::Result::Empire');
our $spies = $db->resultset('Lacuna::DB::Result::Spies');
our $ships = $db->resultset('Lacuna::DB::Result::Ships');

out('getting empires...');
my $saben = $empires->find(-1);
my $lec = $empires->find(1);


out('Looping through colonies...');
my $colonies = $saben->planets;
while (my $colony = $colonies->next) {
    next if $colony->id == $saben->home_planet_id;
    if ($colony->happiness < 0) {
        $colony->add_news(200, '$%^#%^#!%~!~!*::::::::........');
        $colony->add_news(200, sprintf('You may have stopped our efforts on %s, but this war is far from over! We are Sābēn. We will not be defeated!', $colony->name));
        $colony->add_news(200, '^#%$$^#!%~!~:::::::........');
        $colony->sanitize;
        next;
    }
    # check existing target, switch if needed
    # determine closest colony of target
    # check if a probe exists, if not cancel attack
    # send ships
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


