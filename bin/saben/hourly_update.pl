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

out('getting empires...');
my $saben = $empires->find(-1);
my $lec = $empires->find(1);


out('Looping through colonies...');
my $colonies = $saben->planets;
while (my $colony = $colonies->next) {
    next if $colony->id == $saben->home_planet_id;
    set_defenders($colony);
    burn_captured_spies($colony);
    train_spies($colony);
    build_ships($colony);
    repair_buildings($colony);
    run_missions($colony);
}


my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");




###############
## SUBROUTINES
###############

sub burn_captured_spies {
    my $colony = shift;
    my $captured_spies = $spies->search({from_body_id => $colony->id, on_body_id => {'!=', $colony->id}, task=>'Captured'});
    while (my $spy = $captured_spies->next) {
        $spy->burn;
    }
}

sub repair_buildings {
    my $colony = shift;
    my $buildings = $colony->buildings;
    while (my $building = $buildings->next) {
        if ($building->efficiency < 100) {
            my $costs = $building->get_repair_costs;
            if (eval{$building->can_repair($costs)}) {
                $building->repair($costs);
            }
        }
    }
}

sub run_missions {
    my $colony = shift;
    my @missions = ('Sabotage Infrastructure','Sabotage Resources','Hack Network 19','Incite Mutiny','Assassinate Operatives','Incite Rebellion');
    my $mission = $missions[rand @missions];
    my $infiltrated_spies = $spies->search({from_body_id => $colony->id, on_body_id => {'!=', $colony->id}});
    while (my $spy = $infiltrated_spies->next) {
        if ($spy->is_available) {
            eval{$spy->assign($mission)};
        }
    }
}

sub train_spies {
    my $colony = shift;
    my $intelligence = $colony->get_building_of_class('Lacuna::DB::Result::Building::Intelligence');
    my $costs = $intelligence->training_costs;
    if (eval{$intelligence->can_train_spy($costs)}) {
        $intelligence->spend_resources_to_train_spy($costs);
        $intelligence->train_spy($costs->{time});
    }
}

sub build_ships {
    my $colony = shift;
    my $shipyards = $colony->get_buildings_of_class('Lacuna::DB::Result::Building::Shipyard');
    my $shipyard1 = $shipyards->next;
    my $shipyard2 = $shipyards->next;
    my @priorities = [
        ['drone', 3],
        ['probe', 1],
        ['spy_pod', 5],
        ['scanner', randint(5,10)],
        ['scow', randint(3,6)],
        ['snark', 20],
    ];
    my $shipyard = $shipyard2;
    foreach my $priority (@priorities) {
        my $count = $ships->search({body_id => $colony->id, type => $priority->[0]})->count;
        if ($shipyard->id = $shipyard1->id) {
            $shipyard = $shipyard2;
        }
        else {
            $shipyard = $shipyard1;
        }
        if ($count < $priority->[1]) {
            my $ship = $ships->new({type => $priority->[0]});
            my $costs = $shipyard->get_ship_costs($ship);
            if (eval{$shipyard->can_build_ship($ship, $costs)}) {
                $shipyard->spend_resources_to_build_ship($costs);
                $shipyard->build_ship($ship, $costs->{seconds});
            }
        }
    }
}

sub set_defenders {
    my $colony = shift;
    my $local_spies = $spies->search({from_body_id => $colony->id, on_body_id => $colony->id});
    my $count = 0;
    while (my $spy = $local_spies->next) {
        if ($spy->is_available) {
            if ($spy->task eq 'Counter Espionage') {
                $count++;
            }
            else {
                $spy->task('Counter Espionage');
                $spy->update;
                $count++;
            }
        }
        last if $count >= 3;
    }
}




sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


