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
    next unless (defined $saben_colony);
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
    my $count = $db->resultset('Lacuna::DB::Result::Probes')->search({ empire_id => -1, star_id => $target_colony->star_id })->count;
    if ($count) {
        out('Has one at star already...');
        return 1;
    }
    my $probe = $ships->search({body_id => $saben_colony->id, type => 'probe', task=>'Docked'},{rows => 1})->single;
    if (defined $probe) {
        out('Has a probe to launch...');
        $probe->send(target => $target_colony->star);
        sleep $probe->date_available->epoch - time();
        return 1;
    }
    out('No probe. Cancel assault.');
    return 0;
}

sub attack {
    my ($saben_colony, $target_colony) = @_;
    out('Attack!');
    my $available_ships = $ships->search({ task=>'Docked', body_id => $saben_colony->id});
    my $available_spies = $spies->search({ task => 'Counter Espionage', on_body_id => $saben_colony->id, from_body_id => $saben_colony->id });
    while (my $ship = $available_ships->next) {
        if (eval{$ship->can_send_to_target($target_colony)}) {
            out('Sending '.$ship->type_formatted);
            my $payload = {};
            if ($ship->type eq 'spy_pod') {
                my $spy = $available_spies->next;
                unless (defined $spy) {
                    out('No spies available.');
                    next;
                }
                $spy->available_on(DateTime->now->add(seconds=>$ship->calculate_travel_time($target_colony)));
                $spy->on_body_id($target_colony->id);
                $spy->task('Travelling');
                $spy->started_assignment(DateTime->now);
                $spy->update;
                $payload = { spies => [ $spy->id ] };                
            }
            $ship->send(target => $target_colony, payload => $payload);
        }
    }
}



sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


