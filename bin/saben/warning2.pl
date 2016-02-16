use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use List::MoreUtils qw(uniq);
use utf8;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);



out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire');

out('getting empires...');
my $saben = $empires->find(-1);
my $lec = $empires->find(1);

out('Sending warning...');
my $message = q{Our recon teams have spotted a fleet of over 50 colony ships leaving the Sābēn staging colony in fringe space. It looks like they should reach the center of the Expanse in about a week, two at the most. We have no idea if there will be more, or if more have already left before we discovered that the Sābēn were back. This is far worse than we thought it would be. 

We still are unsure what their plan of attack is, but we do know that it is more bold than anything we expected. We thought they'd start a single point of attack and push forward. However, the colony ships seem to be spreading out. Their current trajectory indicates that they will cover many zones at once. Maybe as much as -2|-1 to 2|3.

This tactic means that we won't be able to defend you. We simply do not have the ships or the ship building capabilitiy to cover so much area. You and your allies will have to defend each other. I wish I had better news, however, we'll still be happy to supply you with resources for all your ship building needs. You do still have that Subspace Transporter I gave you, right?

Your Trading Partner,

Tou Re Ell
Lacuna Expanse Corp};
$empires = $empires->search({tutorial_stage => 'turing'});
while (my $empire = $empires->next) {
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'Ships Spotted',
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


