use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,
);



out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
our $empires = $db->resultset('Lacuna::DB::Result::Empire');
our $spies = $db->resultset('Lacuna::DB::Result::Spies');
our $ships = $db->resultset('Lacuna::DB::Result::Ships');
our $targets = $db->resultset('Lacuna::DB::Result::SabenTarget');

out('getting empires...');
my $saben = $empires->find(-1);
my $lec = $empires->find(1);


out('Looping through colonies...');
while (my $target = $targets->next) {
    my $saben_colony = $target->saben_colony;
    return undef unless (defined $saben_colony);
    out('Found colony '.$saben_colony->name);
    if ($saben_colony->happiness < 0) {
        out('Colony has been overcome by players.');
        $saben_colony->add_news(200, '$%^#%^#!%~!~!*::::::::........');
        $saben_colony->add_news(200, sprintf('You may have stopped our efforts on %s, but this war is far from over! We are Sābēn. We will not be defeated!', $saben_colony->name));
        $saben_colony->add_news(200, '^#%$$^#!%~!~:::::::........');
        $saben_colony->sanitize;
        $target->delete;
        next;
    }
    out('Finding target body to attack...');
    my $target_colony = $target->find_closest_target_planet;
    if (defined $target_colony) {
        out('Can attack '.$target_colony->name);
    }
    else {
        out('No colony worth attacking.');
        next;
    }
    next unless has_probe($saben_colony, $target_colony);
    attack($saben_colony, $target_colony);
}


my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");




###############
## SUBROUTINES
###############


sub has_probe {
    my ($saben_colony, $target_colony) = @_;
    out('Looking for probes...');
    my $count = $ships->search({body_id => $saben_colony, type => 'probe'})->count;
    if ($count) {
        out('Has a probe to launch...');
        return 1;
    }
    $count = $db->resultset('Lacuna::DB::Result::Probes')->search({ empire_id => -1, star_id => $target_colony->star_id })->count;
    if ($count) {
        out('Has one at star already...');
        return 1;
    }
    out('No probe. Cancel assault.');
    return 0;
}

sub attack {
    my ($saben_colony, $target_colony) = @_;
    out('Attack!');
    my $available_ships = $ships->search({ task=>'Docked', body_id => $saben_colony->id});
    while (my $ship = $available_ships->next) {
        my $target = $ship->type eq 'probe' ? $target_colony->star : $target_colony;
        if (eval{$ship->can_send_to_target($target)}) {
            out('Sending '.$ship->type_formatted);
            $ship->send($target);
        }
    }
}



sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


