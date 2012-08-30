use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
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

my $message = q{Over the past three years the Expanse has seen an explosion of new races seeking assylum from whatever they left behind. We were glad to have the new trading partners. However, some of you may have inadvertantly destroyed us all. The Sābēn Demesne were nothing compared to the threat we face now.
    
It has come to my attention that some of you have been experimenting with singularities through devices you call Black Hole Generators. These technologies are barely within your comprehension, yet you use them as freely as you peel a Beeldeban! These devices are dangerous. I'm sure you've experienced some of their side-effects, but what you do not understand can kill us all. 

A storm approaches. Those of you manipulating these singularities have built up a form of energy on the entire expanse. It's like the static electricity that's built up on your body when you walk across carpet in wool socks; only in this case, the energy envelops the entire expanse. When this energy discharges, it could form a cosmic string, ripping a hole in the fabric of space and time itself! 

Stop using these blasted devices now, while we try to sort out how to resolve this mess. 

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
        subject     => 'A Storm Approaches',
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


