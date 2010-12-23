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
GetOptions(
    'quiet'         => \$quiet,
    'randomize'         => \$randomize,
);



out('Started');
my $start = time;

if ($randomize) {
    sleep randint(0, 60*60*18); # attack anytime in the next 18 hours.
}


out('Loading DB');
our $db = Lacuna->db;
our $empires = $db->resultset('Lacuna::DB::Result::Empire');
our $spies = $db->resultset('Lacuna::DB::Result::Spies');
our $ships = $db->resultset('Lacuna::DB::Result::Ships');
my $config = Lacuna->config;

out('getting empires...');
my $diablotin = $empires->find(-7);


out('Looping through colonies...');
my $colonies = $diablotin->planets;
my @attacks;
while (my $attacking_colony = $colonies->next) {
    out('Found colony to attack from named '.$attacking_colony->name);
    out('Finding target body to attack...');
    my $targets = $db->resultset('Lacuna::DB::Result::Map::Body')->search({
        empire_id                   => { '>' => 1 },
        'empire.is_isolationist'    => 0,
    },
    {
        order_by    => 'rand()',
        rows        => 4,
        join        => 'empire',
    });
    my @ships = qw(thud placebo placebo2 placebo3);
    while (my $target_colony = $targets->next) {
        push @attacks, start_attack($attacking_colony, $target_colony, shift @ships);
    }
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
    my ($attacking_colony, $target_colony, $ship_type) = @_;
    out('Looking for probes...');
    my $attack = AnyEvent->condvar;
    my $count = $db->resultset('Lacuna::DB::Result::Probes')->search({ empire_id => -1, star_id => $target_colony->star_id })->count;
    if ($count) {
        out('Has one at star already...');
        my $timer; $timer = AnyEvent->timer(
            after   => 1,
            cb      => sub {
                send_ships($attacking_colony, $target_colony, $ship_type);
                $attack->send;
                undef $timer;
            },
        );
        return $attack;
    }
    my $probe = $ships->search({body_id => $attacking_colony->id, type => 'probe', task=>'Docked'},{rows => 1})->single;
    if (defined $probe) {
        out('Has a probe to launch for '.$target_colony->name.'...');
        $probe->send(target => $target_colony->star);
        my $seconds = $probe->date_available->epoch - time();
        out('Probe will arrive in '.$seconds.' seconds.');
        my $timer; $timer = AnyEvent->timer(
            after   => $seconds,
            cb      => sub {
                send_ships($attacking_colony, $target_colony, $ship_type);
                $attack->send;
                undef $timer;
            },
        );
        return $attack;
    }
    out('No probe. Cancel assault.');
    $attack->send;
    return $attack;
}

sub send_ships {
    my ($attacking_colony, $target_colony, $ship_type) = @_;
    out('Attack!');
    my $available_ships = $ships->search({ type => $ship_type, task=>'Docked', body_id => $attacking_colony->id});
    while (my $ship = $available_ships->next) {
        if (eval{$ship->can_send_to_target($target_colony)}) {
            out('Sending '.$ship->type_formatted.' to '.$target_colony->name.'...');
            $ship->send(target => $target_colony);
        }
    }
}

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


