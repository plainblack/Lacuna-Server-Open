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
my $empires = $db->resultset('Empire');

my $lec = $empires->find(1);

if (not $all) {
    $empires = $empires->search({ is_admin => 1 });
}

$empires = $empires->search({ id => {'>' => 1}});

my $message = q{As it is approaching what your Species calls 'Christmas' it seems that it
is now traditional to send gifts to each other at this time.

In order to foster good will between all species we have taken the liberty of sending you
two plans for Sub Space Depots.

How you use these is up to you. You may use them yourselves, perhaps on one of your new 
colonies. Some of the more mature species may decide that at your level of technology
you have little use for them yourselves, in which case you may wish to extend the 
hand/tenticle/pseudopod (delete as appropriate) of friendship and share them with some of
the less developed empires.

In any case, we wish you well for your next solar orbital period.

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
        subject     => 'A Gift.',
        from        => $lec,
        body        => $message,
    );

    Lacuna->db->resultset('Plan')->create({
        body_id     => $home->id,
        class       => 'Lacuna::DB::Result::Building::SubspaceSupplyDepot',
        level       => 1,
        extra_build_level   => 0,
        quantity    => 2,
    });
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


