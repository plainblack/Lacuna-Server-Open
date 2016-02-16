use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Lacuna::AI::DeLambert;
use Getopt::Long;
use List::MoreUtils qw(uniq);
use utf8;
$|=1;
our $quiet;
our $to_all;
our $to_alliance;
our $to_empire;
our $attackers;
GetOptions(
    'quiet'          => \$quiet,  
    'all'            => \$to_all,
    'alliance=s'     => \$to_alliance,
    'empire=s'       => \$to_empire,
    'attackers=s'    => \$attackers,
);

out('Started');
my $start = time;

if (not $attackers) {
    out('ERROR: Must specify attackers');
    exit;
}

out('Loading DB');
our $db = Lacuna->db;
my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({
});

out('getting empires...');
my $de_lambert = Lacuna::AI::DeLambert->new;

out("Sending attack message about '$attackers'");

while (my $empire = $empires->next) {
    my $send_email = 0;
    if ($to_all) {
        $send_email = 1;
    }
    if ($empire->name eq 'icd' or $empire->name eq 'icydee' or $empire->name eq 'Sweden' or $empire->name eq 'Norway') {
        $send_email = 1;
    }
    if ($to_empire and $to_empire eq $empire->name) {
        $send_email = 1;
    }
    if ($to_alliance and $empire->alliance and $empire->alliance->name eq $to_alliance) {
        $send_email = 1;
    }
    if ($send_email) {
        out("Email to ".$empire->name);

        $de_lambert->attack_email($empire, $attackers);
    }
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


