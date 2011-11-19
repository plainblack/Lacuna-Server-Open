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
our $all;
GetOptions(
    'quiet'      => \$quiet,  
    'all'        => \$all,
);



out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({
});

out('getting empires...');
my $de_lambert = $empires->find(-9);

out('Sending introduction');
my $message = q{
We the DeLamberti greet you. 

We have for some time been keeping a close watch on the Expanse and have been pleased that you now seem to have entered a peaceful phase of existance. (We of course do not count the likes of the Sābēn in this greeting but we see that you are more than able to contain their aggressive nature).

Let me tell you a little about ourselves.

Our species originally evolved on a high Gravitational world, a Gas Giant, and as such we are physically strong, but short in stature (please don't mock our height, we find it insulting and that is the one thing that will cause us to lose our peaceful composure). For that reason we prefer to set up trading posts on Gas Giants, but for strategic purposes we may from time to time set up smaller outposts on terrestrial type planets.

Due to a lack of resources on our original world we were forced to develop our skills as a trading species. That is our strongest ability and we have learned it over many eons through our contact with countless other species.

We now wish to enter into peaceful trade with you and we will shortly be setting up a number of trading posts close to your centres of population. Please don't be afraid, we will not occupy any system with populated planets.

Once established, we will connect to your sub-space transporter network and start to offer our goods. (The technology used by your sub-space transporter seems simple enough compaired to ours and our scientists assure us that it will pose no more problem than it took to break into this, your crude communication network).

Please let me assure you again, we are peaceful traders, we pose no threat to you so long as you keep your peace with us.

Watch this space, for more news and for our imminent arrival.

Guillaume de Lambert 9th
};

if (not $all) {
    # if not all then just send to admins
    $empires = $empires->search({name => ['icd','icydee','Sweden','Norway']});
}
$empires = $empires->search({id => {'>' => 1}});

while (my $empire = $empires->next) {
    out("From ".$de_lambert->name." to ".$empire->name);
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'The DeLamberti',
        from        => $de_lambert,
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


