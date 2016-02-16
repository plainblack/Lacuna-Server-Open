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
    'quiet' => \$quiet,    'all'   => \$all,
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

my $message = q{Luckily we appear to have weathered the storm, but it appears that the Expanse is forever changed. 

Early sensor data indicates that the energy ribbon did not in-fact destroy the Expanse, but rather evolved it. Many bodies have changed their very composition. In many ways this is an entirely new Expanse. I'm sure that adventure seekers will love the opportunities for exploration, but we stand reserved.

Your immaturity as a species is showing. You rush to use the latest technologies without fully understanding the implications of that usage. Your decisions affect not only your empire, but the whole Expanse. You didn't destroy us this time, but we were pushed to the brink of annihilation. Please pursue a higher aptitude with the technologies you acquire before putting them to use in the future.

Now that we know there is a future, we look forward to hearing your reports about what you find in this new Expanse. Our probes are showing some anomalous readings. They're indicating that there are entirely new planetary compositions in the Expanse. This seems unlikely, but perhaps you would be so kind as to verify our readings. 

Good luck. And please be careful.
    
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
        subject     => 'Forever Changed',
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


