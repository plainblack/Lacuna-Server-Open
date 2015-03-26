use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
use JSON;
use SOAP::Amazon::S3;
use Lacuna::Constants qw(SHIP_TYPES);
use utf8;


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
  delete_old_records($start);
  rank_spies();
  generate_overview();

  my $finish = time;
  out('Finished');
  out((($finish - $start->epoch)/60)." minutes have elapsed");
exit;


###############
## SUBROUTINES
###############

sub generate_overview {
    out('Generating Overview');
    my $spies       = $db->resultset('Lacuna::DB::Result::Spies')->search({empire_id => { '>' => 1}});
    
    # basics
    out('Getting Basic Counts');
    my %out = (
        spies       => {
            count                           => $spies->count,
            average_defense                 => $spies->get_column('defense')->func('avg'),
            highest_defense                 => $spies->get_column('defense')->max,
            average_offense                 => $spies->get_column('offense')->func('avg'),
            highest_offense                 => $spies->get_column('offense')->max,
            average_intel                   => $spies->get_column('intel_xp')->func('avg'),
            highest_intel                   => $spies->get_column('intel_xp')->max,
            average_mayhem                  => $spies->get_column('mayhem_xp')->func('avg'),
            highest_mayhem                  => $spies->get_column('mayhem_xp')->max,
            average_politics                => $spies->get_column('politics_xp')->func('avg'),
            highest_politics                => $spies->get_column('politics_xp')->max,
            average_theft                   => $spies->get_column('theft_xp')->func('avg'),
            highest_theft                   => $spies->get_column('theft_xp')->max,
            idle_count                      => $spies->search({task => 'Idle'})->count,
            countering_espionage_count      => $spies->search({task => 'Counter Espionage'})->count +
                                               $spies->search({task => 'Debriefing'})->count,
            security_count                  => $spies->search({task => 'Security Sweep'})->count,
            propaganda_count                => $spies->search({task => 'Political Propaganda'})->count,
            gathering_intelligence_count    => $spies->search({task => 'Gather Empire Intelligence'})->count +
                                               $spies->search({task => 'Gather Operative Intelligence'})->count +
                                               $spies->search({task => 'Gather Resource Intelligence'})->count,
            hacking_networks_count          => $spies->search({task => 'Hack Network 19'})->count,
            inciting_count                  => $spies->search({task => 'Incite Rebellion'})->count +
                                               $spies->search({task => 'Incite Mutiny'})->count +
                                               $spies->search({task => 'Incite Insurrection'})->count,
            sabotaging_count                => $spies->search({task => 'Sabotage BHG'})->count +
                                               $spies->search({task => 'Sabotage Infrastructure'})->count +
                                               $spies->search({task => 'Sabotage Probes'})->count +
                                               $spies->search({task => 'Sabotage Resource'})->count,
            stealing_count                  => $spies->search({task => 'Appropriate Technology'})->count +
                                               $spies->search({task => 'Appropriate Resources'})->count,
            training_count                  => $spies->search({task => 'Training'})->count,
            extra_training_count            => $spies->search({task => 'Intel Training'})->count +
                                               $spies->search({task => 'Mayhem Training'})->count +
                                               $spies->search({task => 'Politics Training'})->count +
                                               $spies->search({task => 'Theft Training'})->count,
            extraction_count                => $spies->search({task => 'Rescue Comrades'})->count,
            antipersonal_count              => $spies->search({task => 'Abduct Operatives'})->count +
                                               $spies->search({task => 'Assassinate Operatives'})->count,
            for_sale_count                  => $spies->search({task => 'Mercenary Transport'})->count,
            travelling_count                => $spies->search({task => 'Travelling'})->count,
            infiltrating_count              => $spies->search({task => 'Infiltrating'})->count,
            in_prison_count                 => $spies->search({task => 'Captured'})->count + $spies->search({task => 'Prisoner Transport'})->count,
            unconscious_count               => $spies->search({task => 'Unconscious'})->count,
        },
    );

    out('Write To S3');
    my $config = Lacuna->config;
    my $s3 = SOAP::Amazon::S3->new($config->get('access_key'), $config->get('secret_key'), { RaiseError => 1 });
    my $bucket = $s3->bucket($config->get('feeds/bucket'));
    # fetch existing overview
    my $old_object = $bucket->object('server_overview.json');
    my $stats  = from_json( $old_object->getdata );
    # replace old spies data with new
    $stats->{spies} = $out{spies};
    # save updated data
#XXX
#  my $spy_txt = JSON->new->pretty->canonical->utf8->encode($stats);
#  open(OUT, ">:utf8:", "spies.json");
#  print OUT $spy_txt;
#  close(OUT);
#XXX
    my $object = $bucket->putobject('server_overview.json', to_json($stats), { 'Content-Type' => 'application/json' });
    $object->acl('public');
}


sub rank_spies {
    out('Ranking Spies');
    my $spies = $db->resultset('Lacuna::DB::Result::Log::Spies');
    foreach my $field (qw(level success_rate dirtiest)) {
        my $ranked = $spies->search(undef, {order_by => {-desc => $field}});
        my $counter = 1;
        while (my $spy = $ranked->next) {
            $spy->update({$field.'_rank' => $counter++});
        }
    }
}

sub delete_old_records {
    out('Deleting old records');
    my $start = shift;
    $db->resultset('Lacuna::DB::Result::Log::Spies')->search({date_stamp => { '<' => $start}})->delete;
}



sub summarize_spies {
    out('Summarizing Spies');
    my $spies = $db->resultset('Lacuna::DB::Result::Spies')->search({ empire_id   => {'>' => 1} });
    my $logs = $db->resultset('Lacuna::DB::Result::Log::Spies');
    while (my $spy = $spies->next) {
        out($spy->id.":".$spy->name);
        my $log = $logs->search({ spy_id => $spy->id } )->first;
        my $offense_success_rate = ($spy->offense_mission_count) ? 100 * $spy->offense_mission_successes / $spy->offense_mission_count : 0;
        my $defense_success_rate = ($spy->defense_mission_count) ? 100 * $spy->defense_mission_successes / $spy->defense_mission_count : 0;
        my $success_rate = $offense_success_rate + $defense_success_rate;
        my $planet = $db->resultset('Lacuna::DB::Result::Map::Body')->find($spy->from_body_id);
        next unless defined $planet;
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
            age                         => time - $spy->date_created->epoch,
            times_captured              => $spy->times_captured,
            times_turned                => $spy->times_turned,
            seeds_planted               => $spy->seeds_planted,
            spies_killed                => $spy->spies_killed,
            spies_captured              => $spy->spies_captured,
            spies_turned                => $spy->spies_turned,
            things_destroyed            => $spy->things_destroyed,
            things_stolen               => $spy->things_stolen,
            dirtiest                    => ($spy->seeds_planted + $spy->spies_killed + $spy->spies_captured +
                                            $spy->spies_turned + $spy->things_destroyed + $spy->things_stolen),
            dirtiest_delta              => 0,
            empire_id                   => $spy->empire_id,
            empire_name                 => $spy->empire->name,
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


