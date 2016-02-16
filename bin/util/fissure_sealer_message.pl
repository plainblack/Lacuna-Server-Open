use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
our $all;
GetOptions(
    'quiet' => \$quiet,
    'all'   => \$all,
);


out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
my $empires = $db->resultset('Lacuna::DB::Result::Empire');

my $lec = $empires->find(1);

if (not $all) {
    $empires = $empires->search({ is_admin => 1 });
}

$empires = $empires->search({ id => {'>' => 1}});

my $message = q{Despite our warnings about using Black Hole Generators and how they can cause unstable conditions on planets, your scientists have found more uses for them.   Our instruments have noticed more fissures forming recently on unoccupied worlds.

Since we can't seem to get most of you to stop using the Black Hole Generators, our scientists have come up with a way to seal these fissures though it only works on uninhabited planets.

These Fissure Sealers do need to be sent with a quantity of ore, but still have a chance to help seal a fissure even if empty.  In most cases, it will take multiple applications to fully seal a fissure.

We have noticed that some of your scientists have come up with a method to neutralize Black Hole Generators by putting out a field from your Space Stations.  We are glad that some of you have listened to us.

Your Trading Partner,

Tou Re Ell

Lacuna Expanse Corp};

out('Sending Messages');
while (my $empire = $empires->next) {
    my $home = $empire->home_planet;
    next unless defined $home;
    out('Sending message to '.$empire->name);
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'A new device',
        from        => $lec,
        body        => $message,
    );
    
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


