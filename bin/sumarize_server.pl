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

summarize_spies();
summarize_colonies();
summarize_empires();
delete_old_records($start);
rank_empires();

my $finish = DateTime->now;
out('Finished');
out((to_seconds($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

sub rank_empires {
    my $empires = $db->resultset('Lacuna::DB::Result::Empire');
    foreach my $field (qw(empire_size university_level offense_success_rate defense_success_rate dirtiest))
        my $ranked = $empires->search(undef, {order_by => 'empire_size'});
        my $counter = 1;
        while ($empire = $ranked->next) {
            $empire->update({$field.'_rank' => $counter});
        }
    }
}

sub delete_old_records {
    out('Deleting old records');
    my $start = shift;
    $db->resultset('Lacuna::DB::Result::Log::Empire')->search({date_stamp => { '<' => $start}})->delete;
    $db->resultset('Lacuna::DB::Result::Log::Colony')->search({date_stamp => { '<' => $start}})->delete;
    $db->resultset('Lacuna::DB::Result::Log::Spies')->search({date_stamp => { '<' => $start}})->delete;
}

sub summarize_empires { 
    out('Summarizing Empires');
    my $logs = $db->resultset('Lacuna::DB::Result::Log::Empire');
    my $empires = $db->resultset('Lacuna::DB::Result::Empire');
    my $colony_logs = $db->resultset('Lacuna::DB::Result::Log::Colony');
    while (my $empire = $empires->next) {
        out($empire->name);
        my %empire_data = (
            date_stamp                 => DateTime->now,
            university_level           => $empire->university_level
        );
        my $colonies = $colony_logs->search({empire_id => $empire->id});
        while ( my $colony = $colonies->next) {
            $empire_data{colony_count}++;
            $empire_data{population} 		        += $colony->population;
            $empire_data{population_delta} 		    += $colony->population_delta;
            $empire_data{building_count} 	        += $colony->building_count;
            $empire_data{average_building_level}    += $colony->average_building_level;
            $empire_data{highest_building_level}    =  $colony->highest_building_level if ($colony->highest_building_level > $empire_data{highest_building_level});
            $empire_data{food_hour} 		        += $colony->food_hour;
            $empire_data{ore_hour} 		            += $colony->ore_hour;
            $empire_data{energy_hour} 		        += $colony->energy_hour;
            $empire_data{water_hour} 		        += $colony->water_hour;
            $empire_data{waste_hour} 		        += $colony->waste_hour;
            $empire_data{happiness_hour} 		    += $colony->happiness_hour;
            $empire_data{defense_success_rate}      += $colony->defense_success_rate;
            $empire_data{defense_success_rate_delta}+= $colony->defense_success_rate_delta;
            $empire_data{offense_success_rate}      += $colony->offense_success_rate;
            $empire_data{offense_success_rate_delta}+= $colony->offense_success_rate_delta;
            $empire_data{dirtiest}                  += $colony->dirtiest;
            $empire_data{dirtiest_delta}            += $colony->dirtiest_delta;
            $empire_data{spy_count}                 += $colony->spy_count;
        }
        if ($empire_data{colony_count}) {
       	    $empire_data{average_building_level}    = $empire_data{average_building_level} / $empire_data{colony_count};
            $empire_data{offense_success_rate}      = $empire_data{offense_success_rate} / $empire_data{colony_count};
            $empire_data{defense_success_rate}      = $empire_data{defense_success_rate} / $empire_data{colony_count};
        }
        $empire_data{empire_size} = $empire_data{colony_count} * $empire_data{population};
        my $log = $logs->search({empire_id => $empire->id},{rows=>1})->single;
        if (defined $log) {
            $empire_data{colony_count_delta} = $empire_data{colony_count} - $log->colony_count + $log->colony_count_delta;
            $empire_data{empire_size_delta} = ($empire_data{colony_count_delta}) ? $empire_data{colony_count_delta} * $empire_data{population_delta} : $empire_data{population_delta};
            $log->update(\%empire_data);
        }
        else {
            $empire_data{empire_id}	= $empire->id;
            $empire_data{empire_name}   = $empire->name;
            $logs->new(\%empire_data)->insert;
        }
    }
}

sub summarize_colonies { 
    out('Summarizing Planets');
    my $logs = $db->resultset('Lacuna::DB::Result::Log::Colony');
    my $planets = $db->resultset('Lacuna::DB::Result::Map::Body')->search({ empire_id   => {'>' => 0} });
    my $spy_logs = $db->resultset('Lacuna::DB::Result::Log::Spies');
    while (my $planet = $planets->next) {
        out($planet->name);
        my $log = $logs->search({planet_id => $planet->id},{rows=>1})->single;
        my %colony_data = (
            date_stamp             => DateTime->now,
            planet_name            => $planet->name,
            building_count         => $planet->buildings->count,
            population             => $planet->population,
            average_building_level => $planet->buildings->get_column('level')->func('avg'),
            highest_building_level => $planet->buildings->get_column('level')->max,
            food_hour              => $planet->food_hour,
            water_hour             => $planet->water_hour,
            waste_hour             => $planet->waste_hour,
            energy_hour            => $planet->energy_hour,
            ore_hour               => $planet->ore_hour,
        );
        my $spies = $spy_logs->search({planet_id => $planet->id});
        while (my $spy = $spies->next) {
    	    $colony_data{spy_count}++;
            $colony_data{offense_success_rate}          += $spy->offense_success_rate;
            $colony_data{offense_success_rate_delta}    += $spy->offense_success_rate_delta;
            $colony_data{defense_success_rate}          += $spy->defense_success_rate;
            $colony_data{offense_success_rate_delta}    += $spy->defense_success_rate_delta;
            $colony_data{dirtiest}                      += $spy->dirtiest;
            $colony_data{dirtiest_delta}                += $spy->dirtiest_delta;
        }
        $colony_data{offense_success_rate} = ($colony_data{spy_count}) ? $colony_data{offense_success_rate} / $colony_data{spy_count} : 0;
        $colony_data{defense_success_rate} = ($colony_data{spy_count}) ? $colony_data{defense_success_rate} / $colony_data{spy_count} : 0;
        if (defined $log) {
            $log->update(\%colony_data);
        }
        else {
            $colony_data{empire_id}    = $planet->empire_id;
            $colony_data{empire_name}  = $planet->empire->name;
            $colony_data{planet_id}    = $planet->id;
            $logs->new(\%colony_data)->insert;
        }
    }
}

sub summarize_spies {
    out('Summarizing Spies');
    my $spies = $db->resultset('Lacuna::DB::Result::Spies');
    my $logs = $db->resultset('Lacuna::DB::Result::Log::Spies');
    while (my $spy = $spies->next) {
        out($spy->name);
        my $log = $logs->search({ spy_id => $spy->id },{ rows => 1 } )->single;
        my $offense_success_rate = ($spy->offense_mission_count) ? $spy->offense_mission_successes / $spy->offense_mission_count : 0;
        my $defense_success_rate = ($spy->defense_mission_count) ? $spy->defense_mission_successes / $spy->defense_mission_count : 0;
        my $success_rate = $offense_success_rate + $defense_success_rate;
        my $planet = $db->resultset('Lacuna::DB::Result::Map::Body')->find($spy->from_body_id);
        my %spy_data = (
            date_stamp                  => DateTime->now,
            spy_name                    => $spy->name,
            planet_id                   => $spy->from_body_id,
            planet_name                 => $planet->name,
            level                       => $spy->level,
            level_delta                 => 0,
            offense_success_rate        => $offense_success_rate,
            offense_success_rate_delta  => 0,
            defense_success_rate        => $defense_success_rate,
            defense_success_rate_delta  => 0,
            success_rate                => $success_rate,
            success_rate_delta          => 0,
            age                         => to_seconds(DateTime->now - $spy->date_created),
            times_captured              => $spy->times_captured,
            times_turned                => $spy->times_turned,
            seeds_planted               => $spy->seeds_planted,
            spies_killed                => $spy->spies_killed,
            spies_captured              => $spy->spies_captured,
            spies_turned                => $spy->spies_turned,
            things_destroyed            => $spy->things_destroyed,
            things_stolen               => $spy->things_stolen,
            dirtiest                    => ($spy->seeds_planted + $spy->spies_killed + $spy->spies_captured + $spy->spies_turned + $spy->things_destroyed + $spy->things_stolen),
            dirtiest_delta              => 0,
        );
        if (defined $log) {
            $spy_data{dirtiest_delta}               = $spy_data{dirtiest} - $log->dirtiest + $log->dirtiest_delta;
            $spy_data{level_delta}                  = $spy->level - $log->level;
            $spy_data{defense_success_rate_delta}   = $defense_success_rate - $log->defense_success_rate + $log->defense_success_rate_delta;
            $spy_data{offense_success_rate_delta}   = $offense_success_rate - $log->offense_success_rate + $log->offense_success_rate_delta;
            $spy_data{success_rate_delta}           = $success_rate - $log->success_rate + $log->success_rate_delta;
            $log->update(\%spy_data);
        }
        else {
            $spy_data{empire_id}    = $spy->empire_id;
            $spy_data{empire_name}  = $spy->empire->name;
            $spy_data{spy_id}       = $spy->id;
            $logs->new(\%spy_data)->insert;
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


