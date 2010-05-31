use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date to_seconds);
use Getopt::Long;
$|=1;

our $quiet;

GetOptions(
    'quiet'         => \$quiet,  
);

out('Started');
my $start = DateTime->now;

out('Loading DB');
our $db = Lacuna->db;

out('Processing planets');
my $planets = $db->resultset('Lacuna::DB::Result::Map::Body')->search({ empire_id   => {'>' => 0} });
while (my $planet = $planets->next) {
    out('Ticking '.$planet->name);
    $planet->tick;
    summarize_spies($planet);
    summarize_colony($planet);
}

my $finish = DateTime->now;
out('Finished');
out((to_seconds($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

sub summarize_colony { 
    out('Summarizing Planet');
    my $planet = shift;
    my $logs = $db->resultset('Lacuna::DB::Result::Log::Colony');
    my $log = $logs->search({planet_id => $planet->id},{rows=>1})->single;
    if (defined $log) {
        $log->update({
            planet_name            => $planet->name,
            building_count         => $planet->buildings->count,
            population             => $planet->population,
            average_building_level => $planet->buildings->get_column('level')->func('avg'),
            highest_building_level => $planet->buildings->get_column('level')->max,
            lowest_building_level  => $planet->buildings->get_column('level')->min,
            food_hour              => $planet->food_hour,
            water_hour             => $planet->water_hour,
            waste_hour             => $planet->waste_hour,
            energy_hour            => $planet->energy_hour,
            ore_hour               => $planet->ore_hour,
        });
    }
    else {
        $logs->new({
            empire_id              => $planet->empire_id,
            empire_name            => $planet->empire->name,
            planet_id              => $planet->id,
            date_stamp             => DateTime->now,
            planet_name            => $planet->name,
            building_count         => $planet->buildings->count,
            population             => $planet->population,
            average_building_level => $planet->buildings->get_column('level')->func('avg'),
            highest_building_level => $planet->buildings->get_column('level')->max,
            lowest_building_level  => $planet->buildings->get_column('level')->min,
            food_hour              => $planet->food_hour,
            water_hour             => $planet->water_hour,
            waste_hour             => $planet->waste_hour,
            energy_hour            => $planet->energy_hour,
            ore_hour               => $planet->ore_hour,
        })->insert;
    }
}

sub summarize_spies {
    out('Summarizing Spies');
    my $planet = shift;
    my $spies = $db->resultset('Lacuna::DB::Result::Spies')->search({from_body_id => $planet->id});
    my $logs = $db->resultset('Lacuna::DB::Result::Log::Spies');
    while (my $spy = $spies->next) {
        my $log = $logs->search({ spy_id => $spy->id },{ rows => 1 } )->single;
	my $success_rate = ($spy->mission_count) ? $spy->mission_successes / $spy->mission_count : 0;
        if (defined $log) {
            $log->update({
                date_stamp          => DateTime->now,
                spy_name            => $spy->name,
                level               => $spy->level,
                level_delta         => $spy->level - $log->level,
                success_rate        => $success_rate,
                success_rate_delta  => $success_rate - $log->success_rate,
                age                 => to_seconds(DateTime->now - $spy->date_created),
            });
        }
        else {
            $logs->new({
                empire_id           => $spy->empire_id,
                empire_name         => $spy->empire->name,
                date_stamp          => DateTime->now,
                spy_name            => $spy->name,
                spy_id              => $spy->id,
                level               => $spy->level,
                level_delta         => 0,
                success_rate        => $success_rate,
                success_rate_delta  => 0,
                age                 => to_seconds(DateTime->now - $spy->date_created),
            })->insert;
        }
    }
}


# UTILITIES

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


