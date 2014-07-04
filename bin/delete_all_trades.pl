use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server/lib';
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use DateTime;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);

out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
my $now = DateTime->now;

out('Complete all trades in progress, delete all others');

out('Zip all ships to their destination');
my $ships = $db->resultset('Ships')->search({
    task => 'Travelling'
});
while (my $ship = $ships->next) {
    out('Zooming ship '.$ship->id);
    $ship->update({
        date_available => $now,
    });
}

out('Withdraw all trades');
my $trades = $db->resultset('Market')->search;
while (my $trade = $trades->next) {
    $trade->withdraw($trade->body);
}

out('Do a final tick of all planets');
my $planets_rs = $db->resultset('Map::Body');
my $planets = $planets_rs->search({ empire_id   => {'!=' => 0} });
while (my $planet = $planets->next) {
    out('Ticking '.$planet->name);
    eval{$planet->tick};
    my $reason = $@;
    if (ref $reason eq 'ARRAY' && $reason->[0] eq -1) {
        # this is an expected exception, it means one of the roles took over
    }
    elsif ( ref $reason eq 'ARRAY') {
        out(sprintf("Ticking %s resulted in errno: %d, %s\n", $planet->name, $reason->[0], $reason->[1]));
    }
    elsif ( $reason ) {
        out(sprintf("Ticking %s resulted in: %s\n", $planet->name, $reason));
    }
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

sub out {
    my ($message) = @_;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}

