use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use AnyEvent;
$|=1;
our $quiet;
our $randomize;
my $skipnews;
GetOptions(
    'quiet'         => \$quiet,
    'randomize'         => \$randomize,
    'skipnews'      => \$skipnews,
);



out('Started');
my $start = time;

if ($randomize) {
    if (randint(1,7) <= 2) { # on average 2 attacks per week are what we're looking for
        sleep randint(0, 60*60*18); # attack anytime in the next 18 hours.
    }
    else {
        out('No attacks today.');
        exit;
    }
}


out('Loading DB');
our $db = Lacuna->db;
our $empires = $db->resultset('Empire');
our $spies = $db->resultset('Spies');
our $ships = $db->resultset('Ships');
our $targets = $db->resultset('SabenTarget');
my $config = Lacuna->config;

out('getting empires...');
my $saben = $empires->find(-1);
my $lec = $empires->find(1);

unless ($skipnews) {
    out('Send Network 19 messages....');
    my $news = $db->resultset('News');
    my @messages = (
        'We are Sābēn. We have penetrated your defenses, and found them lacking. Goodbye.',
        'We are Sābēn. We have studied you, and found your weaknesses. You do not have long.',
        'We are Sābēn. You are in our Demesne. You are not welcome here.',
    );
    my $message = $messages[ rand @messages ];
    foreach my $x (int($config->get('map_size/x')->[0]/250) .. int($config->get('map_size/x')->[1]/250)) {
        foreach my $y (int($config->get('map_size/y')->[0]/250) .. int($config->get('map_size/y')->[1]/250)) {
            my $zone = $x.'|'.$y;
            say $zone;
            $news->new({headline => '$~~^#!!^#!@@~!~!*::::::::........', zone => $zone })->insert;
            sleep 1;
            $news->new({headline => $message, zone => $zone })->insert;
            sleep 1;
            $news->new({headline => '^#{}$$^#!+~!~:::::::........', zone => $zone })->insert;
        }
    }
}

out('Looping through colonies...');
my @attacks;
my @timers;
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

    my ($attack, $timer) = start_attack($saben_colony, $target_colony);
    push @attacks, $attack;
    push @timers, $timer;
}

out("Waiting on attacks...");
foreach my $attack (@attacks) {
    $attack->recv if defined $attack;
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");




###############
## SUBROUTINES
###############


sub start_attack {
    my ($saben_colony, $target_colony) = @_;
    out('Looking for probes...');
    my $attack = AnyEvent->condvar;
    my $count = $db->resultset('Probes')->search_any({ empire_id => -1, star_id => $target_colony->star_id })->count;
    if ($count) {
        out('Has one at star already...');
        my $timer = AnyEvent->timer(
            after   => 1,
            cb      => sub {
                send_ships($saben_colony, $target_colony);
                $attack->send;
            },
        );
        return $attack, $timer;
    }
    my $probe = $ships->search({body_id => $saben_colony->id, type => 'probe', task=>'Docked'})->first;
    if (defined $probe) {
        out('Has a probe to launch for '.$target_colony->name.'...');
        $probe->send(target => $target_colony->star);
        my $seconds = $probe->date_available->epoch - time();
        out('Probe will arrive in '.$seconds.' seconds.');
        my $timer = AnyEvent->timer(
            after   => $seconds,
            cb      => sub {
                send_ships($saben_colony, $target_colony);
                $attack->send;
            },
        );
        return $attack, $timer;
    }
    out('No probe. Cancel assault.');
    return $attack->send;
}

sub send_ships {
    my ($saben_colony, $target_colony) = @_;
    out('Attack!');
    my $available_ships = $ships->search({ task=>'Docked', body_id => $saben_colony->id});
    my $available_spies = $spies->search({ task => 'Counter Espionage', on_body_id => $saben_colony->id, from_body_id => $saben_colony->id });
    while (my $ship = $available_ships->next) {
        if (eval{$ship->can_send_to_target($target_colony)}) {
            out('Sending '.$ship->type_formatted.' to '.$target_colony->name.'...');
            my $payload = {};
            if ($ship->type eq 'spy_pod') {
                my $spy = $available_spies->next;
                unless (defined $spy) {
                    out('No spies available.');
                    next;
                }
                $spy->send($target_colony->id, DateTime->now->add(seconds=>$ship->calculate_travel_time($target_colony)))->update;
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


