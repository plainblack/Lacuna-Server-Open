use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use List::MoreUtils qw(uniq);
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
my $config = Lacuna->config;

out('getting empires...');
my $lec = $empires->find(1);

out('Sending warning...');
my $message = q{I hope this message finds you well. I have some very interesting news, but first a little background. 

There is a species among us that arrived a few years before you. They call their government Trelvestian Sveitarfélagi, but themselves Trelvestivð. They never accepted our help as you did. In fact, they've kept entirely to themselves this entire time; not a single response to any of our offers of diplomacy. Many believe they are xenophobes, but I believe we just haven't tried hard enough to learn their language. Perhaps you will do better deciphering their language.

Back to my interesting news; we have recently discovered that Trelvestivð have a secret. They have well over 100 colonies now, and it appears that every one has an Essentia Vein running through the planet. I have no idea how they managed this amazing feat, but my superiors have asked me to see if you and your allies could acquire one of these planets, and trade with us. Unfortunately the war with the Sābēn Demesne have left us in a position where we are unable to do this on our own. Can you help us?
    
Your Trading Partner,

Tou Re Ell
Lacuna Expanse Corp

PS

I feel you and I have become friends since you arrived in the Expanse. Though my superiors wouldn't like it, I must warn you that the Trelvestian Sveitarfélagi fleet is quite powerful. And from our experience the Trelvestivð are the sort to shoot first and never ask any questions. They will consider even the smallest invasion of their privacy an act of war. Be careful.  };
$empires = $empires->search({tutorial_stage => 'turing'});
while (my $empire = $empires->next) {
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'Essentia Veins',
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


