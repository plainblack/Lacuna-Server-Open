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
my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({
});

out('getting empires...');
my $saben = $empires->find(-1);
my $lec = $empires->find(1);

out('Sending warning...');
my $message = q{I hope this message finds you well. I unfortunately have disturbing news. A threat we thought was long since vanquished has risen again. They call themselves Sābēn Demesne. Sābēn are an authoritarian people who believe that the Expanse is theirs. In fact "Sābēn Demesne" literally means "territory owned by Sābēn", and it is their name for the Expanse. The are singled minded in this belief, so negotiation is unfortunately not an option. 

Adding to our problems is their use of alien technology. Some say they have mastered the science of the Great Race, but we do not believe the Great Race ever existed. Great Race or not, they do have advanced technology, and we cannot underestimate their ability to employ it.

I do not know when they will arrive in the center of the Expanse where you are now, but I have received word that they have already been building colonies in fringe space at the edge of the Expanse.

I will send more information as I have it. Just know that war is coming.

Your Trading Partner,

Tou Re Ell

Lacuna Expanse Corp};

$empires = $empires->search({id => {'>' => 1}});

while (my $empire = $empires->next) {
    out("From ".$lec->name." To ".$empire->name);
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'War Is Coming',
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


