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
my $diablotin = $empires->find(-7);


out('Looping through colonies...');
my $colonies = $diablotin->planets;
while (my $colony = $colonies->next) {
    out('Colony: '.$colony->name);
    $colony->tick;
    set_defenders($colony);
    repair_buildings($colony);
    train_spies($colony);
    build_ships($colony);
    run_missions($colony);
}


my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");




###############
## SUBROUTINES
###############

sub run_missions {
    my $colony = shift;
    out('Running missions...');
    my @missions = ('Appropriate Resources','Sabotage Resources');
    my $mission = $missions[rand @missions];
    my $infiltrated_spies = $spies->search({from_body_id => $colony->id, on_body_id => {'!=', $colony->id}});
    while (my $spy = $infiltrated_spies->next) {
        say $spy->id;
        if ($spy->is_available) {
            say "running mission...";
            my $result = eval{$spy->assign($mission)};
            say $result->{result};
        }
        else {
            say "not available";
        }
    }
}

sub repair_buildings {
    my $colony = shift;
    out('Repairing damaged buildings...');
    my $buildings = $colony->buildings;
    while (my $building = $buildings->next) {
        say $building->name;
        if ($building->efficiency < 100) {
            my $costs = $building->get_repair_costs;
            if (eval{$building->can_repair($costs)}) {
                $building->repair($costs);
                say "repaired";
            }
            else {
                say $@->[1];
            }
        }
        else {
            say "does not need to be repaired";
        }
    }
}

sub train_spies {
    my $colony = shift;
    out('Training spies...');
    my $intelligence = $colony->get_building_of_class('Lacuna::DB::Result::Building::Intelligence');
    my $costs = $intelligence->training_costs;
    if (eval{$intelligence->can_train_spy($costs)}) {
        $intelligence->spend_resources_to_train_spy($costs);
        $intelligence->train_spy($costs->{time});
        say "Spy trained.";
    }
    else {
        say $@->[1];
    }
}

sub build_ships {
    my $colony = shift;
    out('Building ships...');
    my @shipyards = $colony->get_buildings_of_class('Lacuna::DB::Result::Building::Shipyard')->search(undef,{order_by => 'work_ends'})->all;
    my @priorities = (
        ['drone', 14],
        ['probe', 4],
        ['thud', 18],
        ['placebo2', 18],
        ['placebo3', 18],
        ['placebo', 18],
    );
    foreach my $priority (@priorities) {
        say $priority->[0];
        my $count = $ships->search({body_id => $colony->id, type => $priority->[0]})->count;
        if ($count < $priority->[1]) {
            my $shipyard = shift @shipyards;
            $shipyard->body($colony);
            my $ship = $ships->new({type => $priority->[0]});
            my $costs = $shipyard->get_ship_costs($ship);
            if (eval{$shipyard->can_build_ship($ship, $costs)}) {
                say "building ".$ship->type;
                $shipyard->spend_resources_to_build_ship($costs);
                $shipyard->build_ship($ship, $costs->{seconds});
            }
            else {
                say $@->[1];
            }
            push @shipyards, $shipyard;
        }
        else {
            say "have enough";
        }
    }
}

sub set_defenders {
    my $colony = shift;
    out('Setting defenders...');
    my $local_spies = $spies->search({from_body_id => $colony->id, on_body_id => $colony->id});
    while (my $spy = $local_spies->next) {
        say $spy->id;
        if ($spy->is_available) {
            if ($spy->task eq 'Counter Espionage') {
                say "already defending";
            }
            else {
                say "setting defender";
                $spy->task('Counter Espionage');
                $spy->update;
            }
        }
        else {
            say "unavailable";
        }
    }
}




sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


