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
        $news->new({headline => 'We are Sābēn. You will regret your insolence. We will end you.', zone => $zone })->insert;
        sleep 1;
        $news->new({headline => '^#%$$^#!%~!~:::::::........', zone => $zone })->insert;
        sleep 1;
        $news->new({headline => 'We are sorry for that unscheduled interruption. We at Network 19 do not endorse the previous transmission.', zone => $zone })->insert;
    }
}

out('Sending warning...');
my $message = q{We are Sābēn. You have been a difficult pest to eradicate. While we have been unable to rid our Demesne of you, we can slow your progress, and eventually you will leave.

Starting today, we will destroy hundreds of worlds per day until you decide to leave. You'll either leave or eventually you'll have no more room to spread. Either way, your blight on our Demense will be extinguished forever.};
$empires = $empires->search({tutorial_stage => 'turing'});
while (my $empire = $empires->next) {
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'You Will Leave',
        from        => $saben,
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


