use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server-Open/lib';
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

out('Complete all ships being built');
my $ships = $db->resultset('Lacuna::DB::Result::Ships')->search({
    task => 'Building',
});
my $now = DateTime->now;
while (my $ship = $ships->next) {
    $ship->update({
        task => 'Docked',
        date_available => $now,
    });
}

out('Zip all ships to their destination');
my $ships = $db->resultset('Lacuna::DB::Result::Ships')->search({
    task => 'Travelling'
});
while (my $ship = $ships->next) {
    out('Zooming ship '.$ship->id);
    $ship->update({
        date_available => $now,
    });
}

out('Withdraw all trades');
my $trades = $db->resultset('Lacuna::DB::Result::Market')->search;
while (my $trade = $trades->next) {
    $trade->withdraw($trade->body);
}

out('Do a final tick of all planets');
my $planets_rs = $db->resultset('Lacuna::DB::Result::Map::Body');
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

out('Group ships into fleets');
$ships = $db->resultset('Lacuna::DB::Result::Ships')->search({},{
    group_by    => [qw(body_id type task name speed stealth combat hold_size berth_level foreign_body_id foreign_star_id)],
    '+select'   => [{count => 'id'}],
    '+as'       => [ qw(quantity) ],
});

out('Delete existing fleets');
my $fleet = $db->resultset('Lacuna::DB::Result::Fleet')->delete_all;

out('Create new fleets');
while (my $ship = $ships->next) {
    my $mark = 'one';
    my $fleet = $db->resultset('Lacuna::DB::Result::Fleet')->create({
        body_id	        => $ship->body_id,
        shipyard_id     => 0,
        date_started    => $now,
        date_available  => $now,
        mark            => $mark,
        type            => $ship->type,
        task            => $ship->task,
        name            => $ship->name,
        speed           => $ship->speed,
        stealth         => $ship->stealth,
        combat          => $ship->combat,
        hold_size       => $ship->hold_size,
        payload         => "{}",
        roundtrip       => 0,
        direction       => 'in',
        foreign_body_id => $ship->foreign_body_id,
        foreign_star_id => $ship->foreign_star_id,
        berth_level     => $ship->berth_level,
        quantity        => $ship->get_column('quantity'),
    });
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

