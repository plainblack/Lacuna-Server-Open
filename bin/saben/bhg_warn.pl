use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
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
my $message = q{I hope this message finds you well. Once again, it looks like your playing with technologies beyond your understanding, may open you up to another attack.  Not only do you have a Cult growing around the worship of fissures, but it appears the Sābēn Demesne have another way to exploit them.

We're not sure what they have planned, but we have monitored their transmissions and they seem to be ready to make another push.  You may want to be extra careful with any Black Hole Generators that you may use.

Your Trading Partner,

Tou Re Ell

Lacuna Expanse Corp};

$empires = $empires->search({id => {'>' => 1}});

while (my $empire = $empires->next) {
    out("From ".$lec->name." To ".$empire->name);
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'BHG Warning',
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


