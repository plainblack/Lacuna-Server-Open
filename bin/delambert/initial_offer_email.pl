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

You may now have seen reports in your Network 19 news that several trading posts have been set up in your area.

We are pleased to tell you that all our trading posts are fully operational, have a full inventory of trade goods and a large fleet of super fast courier ships standing by ready to deliver your orders.

As a one-off, never-to-be-repeated, 30 day trial offer. We would like to make you a gift of a complete set of mint condition glyphs delivered promptly to your planet.

To accept this offer simply reply to this email.

Note, we have taken the liberty to fill in your order form with one gleaming mint condition glyph of each type. You may, if you wish, change the quantities and so long as the total number of glyphs does not exceed 20 we will do our best to honor your request. (should you exceed a total of 20, you will just receive the first 20 glyphs on the order form).

Guillaume de Lambert 9th

----

'Please send me the following mint condition glyphs, delivered to me by your super efficient courier service by return of post'.

1 anthracite
1 bauxite
1 beryl
1 chalcopyrite
1 chromite
1 fluorite
1 galena
1 goethite
1 gold
1 gypsum
1 halite
1 kerogen
1 magnetite
1 methane
1 monazite
1 rutile
1 sulfur
1 trona
1 uraninite
1 zircon

----

small print.
(Offer subject to availability while stocks last. This offer may be withdrawn at any time. No correspondence may be entered into concerning this offer. This offer not available to Diablotin, Saben, Trelvestian or other aggressive species. You must be over the age of consent for your species. Note that combining glyphs in random order may result in dangerous consequences. DeLamberti take no responsibility for subsequent damage, accident or death (both permanent and temporary) caused by our products.)
};

if (not $all) {
    # if not all then just send to admins
    $empires = $empires->search({is_admin => 1});
}

$empires = $empires->search({id => {'>' => 1}});

while (my $empire = $empires->next) {
    out("Emailing ".$empire->name);
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'Special Offer',
        from        => $de_lambert,
        body        => $message,
    );
}


my $finish = time;
out('Finished');
out((int(100*($finish - $start)/60)/100)." minutes have elapsed");




###############
## SUBROUTINES
###############




sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


