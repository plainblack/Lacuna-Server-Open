use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
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


my $message = q{You didn't heed our warning. The storm has been unleashed. All we can do is brace ourselves and hope that the Expanse doesn't tear itself apart as the storm washes over us.

The use of these singularities has created a cosmic string, a ribbon of energy, that is passing over the entire Expanse. The discharge is so great that all ships and probes we've sent to investigate were instantly destroyed. Our sensors cannot see beyond the ribbon, so we are unable to see if the Expanse remains behind it in any form, or if it has been completely destroyed.

We suggest you do what you can to fortify your empire. With any luck the ribbon will not ignite your atmosphere as it washes over your planet. Good luck. Hope to see you on the other side.

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
        subject     => 'A Ribbon of Energy',
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


