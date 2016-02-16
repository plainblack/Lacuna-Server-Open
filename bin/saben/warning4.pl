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
my $saben = $empires->find(-1);
my $lec = $empires->find(1);


out('Send Network 19 messages....');
my $news = $db->resultset('Lacuna::DB::Result::News');
foreach my $x (int($config->get('map_size/x')->[0]/250) .. int($config->get('map_size/x')->[1]/250)) {
    foreach my $y (int($config->get('map_size/y')->[0]/250) .. int($config->get('map_size/y')->[1]/250)) {
        my $zone = $x.'|'.$y;
        say $zone;
        $news->new({headline => '$%^#%^#!%~!~!*::::::::........', zone => $zone })->insert;
        sleep 1;
        $news->new({headline => 'We are Sābēn. You have proven yourselves a difficult infestation to irradicate, but irradicate you we will.', zone => $zone })->insert;
        sleep 1;
        $news->new({headline => '^#%$$^#!%~!~:::::::........', zone => $zone })->insert;
        sleep 1;
        $news->new({headline => 'We are sorry for that unscheduled interruption. We at Network 19 do not endorse the previous transmission.', zone => $zone })->insert;
    }
}

out('Sending warning...');
my $message = q{I don't know how to tell you this, but I fear our days are now numbered in the Expanse. All of this time we thought that the attacks from the Sābēn were the primary force they had been building. Unfortunately that was simply a distraction to keep us busy so we didn't notice the real threat.
    
We have just intercepted and decoded a transmission from a Sābēn mission commander back to their home world in the Dydolad Galaxy. I will share a portion of it with you now:

*Seed 147 in position. Cloak holding. Awaiting seed notification.*

Seed is their word for a colony ship. Our best guess is that there are 200 cloaked colony ships in position just waiting to colonize and attack. That is four times as many colony ships as we have seen from them in the past. 

The war has been brutal for us. We have lost 3 trading colonies, and I'm sure your losses have been severe as well. The lack of activity lately made us believe we were reaching the end of their assault. Our reserves have been depleted. We have little left. Whether we are forced to leave the Expanse is entirely in your hands now.

Good Luck,

Tou Re Ell
Lacuna Expanse Corp};
$empires = $empires->search({tutorial_stage => 'turing'});
while (my $empire = $empires->next) {
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'You Are Not Safe!',
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


