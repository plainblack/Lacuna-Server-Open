use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
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

out('getting empires...');
my $saben = $empires->find(-1);
my $lec = $empires->find(1);


out('Send Network 19 messages....');
$saben->home->add_news(200, '$%^#%^#!%~!~!*::::::::........');
sleep 1;
$saben->home->add_news(200, 'We are Sābēn. You have violated our Demesne. You have seven days to vacate or perish.');
sleep 1;
$saben->home->add_news(200, '^#%$$^#!%~!~:::::::........');
sleep 1;
$saben->home->add_news(200, 'We are sorry for that unscheduled interruption. We at Network 19 do not endorse the previous transmission.');

out('Sending warning...');
my $message = q{I hoped to provide you with more warning, but I must tell you now that war is upon us. We were able to destroy one Sābēn foothold colony in zone 0|0, but our intelligence indicates that there is at least one more and we do not know its location or even which zone it is in. 

You have no doubt seen the messages that Sābēn have broadcast on Network 19. We aren't sure how they have penetrated our broadcast system, but if they are able to do that, who knows what else they have access to, including your systems?

They will start by testing the strongest among us. When they have figured out our weaknesses, they will exploit them and attempt to destroy us. When we are gone they will either destroy or enslave the weak. Our only hope is to locate their foothold colonies, capture their spies, destroy their supply lines, and ultimately demoralize their people. If we can do that, they will retreat, at least for a while.

Good Luck,

Tou Re Ell

Lacuna Expanse Corp};
while (my $empire = $empires->next) {
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'War Is Upon Us',
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


