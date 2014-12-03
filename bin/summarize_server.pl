use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
use JSON;
use SOAP::Amazon::S3;
use Lacuna::Constants qw(SHIP_TYPES ORE_TYPES);
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

  summarize_colonies();
  my $mapping = summarize_empires();
  summarize_alliances();
  delete_old_records($start);
  rank_colonies();
  rank_empires();
  rank_alliances();
  output_map($mapping);
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
    my $stars       = $db->resultset('Map::Star');
    my $bodies      = $db->resultset('Map::Body');
    my @off_limits  = $bodies->search({empire_id => {'<' => 2}})->get_column('id')->all;
    my $ships       = $db->resultset('Ships')->search({body_id => { 'not in' => \@off_limits}});
    my $glyphs      = $db->resultset('Glyph')->search({body_id => { 'not in' => \@off_limits}});
    my $buildings   = $db->resultset('Building')->search({body_id => { 'not in' => \@off_limits}});
    my $empires     = $db->resultset('Empire')->search({id => { '>' => 1}});
    # Get all probes, either observatory or oracle
    my $probes      = $db->resultset('Probes')->search({empire_id => { '>' => 1} });
    my $dtformatter = $db->storage->datetime_parser;
    
    # basics
    out('Getting Basic Counts');
    my %out = (
        stars       => {
            count           => $stars->count,
            # number of probes (observatory)
            probes_count    => $probes->search({virtual => 0})->count,
            # number of probed stars (either observatory or oracle)
            probed_count    => $probes->search(undef, { group_by => ['star_id'] })->count,
            seized_count    => $stars->search({station_id => { '!=' => 'Null' }})->count,
        },
        bodies      => {
            count           => $bodies->count,
            colony_count    => $bodies->search({empire_id => { '>' => 0}})->count,
        },
        ships       => {
            count           => $ships->count,
        },
        buildings   => {
            count           => $buildings->count,
        },
        empires     => {
            count                       => $empires->count,
            average_university_level    => $empires->get_column('university_level')->func('avg'),
            highest_university_level    => $empires->get_column('university_level')->max,
            isolationist_count          => $empires->search({is_isolationist => 1})->count,
            essentia_using_count        => $empires->search({essentia => { '>' => 0 }})->count,
            currently_active_count      => $empires->search({last_login => {'>=' => $dtformatter->format_datetime(DateTime->now->subtract(hours=>1))}})->count,
            active_today_count          => $empires->search({last_login => {'>=' => $dtformatter->format_datetime(DateTime->now->subtract(hours=>24))}})->count,
            active_this_week_count      => $empires->search({last_login => {'>=' => $dtformatter->format_datetime(DateTime->now->subtract(days=>7))}})->count,
        },
    );
    
    # flesh out bodies
    out('Flesh Out Body Stats');
    my %body_types = (
        gas_giants  => 'Lacuna::DB::Result::Map::Body::Planet::GasGiant%',
        habitables  => 'Lacuna::DB::Result::Map::Body::Planet::P%',
        stations    => 'Lacuna::DB::Result::Map::Body::Planet::Station',
        asteroids   => 'Lacuna::DB::Result::Map::Body::Asteroid%',
    );
    foreach my $key (keys %body_types) {
        out($key);
        my $type = $bodies->search({class => {like => $body_types{$key}}});
        $out{bodies}{types}{$key} = {
            count           => $type->count,
            average_size    => $type->get_column('size')->func('avg'),
            largest_size    => $type->get_column('size')->max,
            smallest_size   => $type->get_column('size')->min,
            average_orbit   => $type->get_column('orbit')->func('avg'),
        };
    }

    # flesh out orbits
    out('Flesh Out Orbital Stats');
    foreach my $orbit (1..8) {
      out($orbit);
      $out{orbits}{$orbit} = {
           inhabited   => $bodies->search({empire_id => {'>', 0}, orbit => $orbit})->count,
           bodies      => $bodies->search({orbit => $orbit})->count,
      }
    }

    # flesh out buildings
    out('Flesh Out Building Stats');
    my $distinct = $buildings->search(undef, { group_by => ['class'] })->get_column('class');
    while (my $class = $distinct->next) {
      out($class);
      my $type_rs = $buildings->search({class=>$class});
      my $count = $type_rs->count;
      $out{buildings}{types}{$class->name} = {
           average_level       => $type_rs->get_column('level')->func('avg'),
           highest_level       => $type_rs->get_column('level')->max,
           count               => $count,
      };
    }

    # flesh out ships
    out('Flesh Out Ship Stats');
    foreach my $type (SHIP_TYPES) {
        my $type_rs = $ships->search({type=>$type});
        my $count = $type_rs->count;
        $out{ships}{types}{$type} = {
            average_hold_size   => $type_rs->get_column('hold_size')->func('avg'),
            largest_hold_size   => $type_rs->get_column('hold_size')->max,
            smallest_hold_size  => $type_rs->get_column('hold_size')->min,
            average_speed       => $type_rs->get_column('speed')->func('avg'),
            fastest_speed       => $type_rs->get_column('speed')->max,
            slowest_speed       => $type_rs->get_column('speed')->min,
            count               => $count
        };
    }

    # flesh out glyphs
    out('Flesh Out Glyphs Stats');
    my $glyph_rs = $glyphs->search(undef, {
        group_by => 'type',
        select => [
            'type',
            { sum => 'quantity' },
        ],
        as => [qw(type quantity)],
    });
    while (my $glyph = $glyph_rs->next) {
        $out{glyphs}{types}{$glyph->type} = $glyph->quantity;
    }

    out('Write To S3');
    my $config = Lacuna->config;
    my $s3 = SOAP::Amazon::S3->new($config->get('access_key'), $config->get('secret_key'), { RaiseError => 1 });
    my $bucket = $s3->bucket($config->get('feeds/bucket'));
    # fetch existing overview
    my $old_object = $bucket->object('server_overview.json');
    my $old_stats  = from_json( $old_object->getdata );
    # add old spies data to new data
    $out{spies} = $old_stats->{spies};
    # save updated data
    my $object = $bucket->putobject('server_overview.json', to_json(\%out), { 'Content-Type' => 'application/json' });
    $object->acl('public');
}


sub rank_colonies {
    out('Ranking Colonies');
    my $colonies = $db->resultset('Log::Colony');
    foreach my $field (qw(population)) {
        my $ranked = $colonies->search(undef, {order_by => [ {-desc => $field}, 'rand()']});
        my $counter = 1;
        while (my $colony = $ranked->next) {
            $colony->update({$field.'_rank' => $counter++});
        }
    }
}

sub rank_empires {
    out('Ranking Empires');
    my $empires = $db->resultset('Log::Empire');
    foreach my $field (qw(empire_size university_level offense_success_rate defense_success_rate dirtiest)) {
        my $ranked = $empires->search(undef, {order_by => [ {-desc => $field}, 'rand()']});
        my $counter = 1;
        while (my $empire = $ranked->next) {
            $empire->update({$field.'_rank' => $counter++});
        }
    }
}

sub rank_alliances {
    out('Ranking Alliances');
    my $alliances = $db->resultset('Log::Alliance');
    foreach my $field (qw(influence population space_station_count average_empire_size offense_success_rate defense_success_rate dirtiest)) {
        my $ranked = $alliances->search(undef, {order_by => [{-desc => $field},'rand()']});
        my $counter = 1;
        while (my $alliance = $ranked->next) {
            $alliance->update({$field.'_rank' => $counter++});
        }
    }
}

sub delete_old_records {
    out('Deleting old records');
    my $start = shift;
    $db->resultset('Log::Alliance')->search({date_stamp => { '<' => $start}})->delete;
    $db->resultset('Log::Empire')->search({date_stamp => { '<' => $start}})->delete;
    $db->resultset('Log::Colony')->search({date_stamp => { '<' => $start}})->delete;
}

sub summarize_alliances { 
  out('Summarizing Alliances');
  my $logs = $db->resultset('Log::Alliance');
  my $alliances = $db->resultset('Alliance');
  my $empire_logs = $db->resultset('Log::Empire');
  while (my $alliance = $alliances->next) {
    next if ! defined $alliance->leader_id; # until Alliances get deleted...
      out($alliance->name);
    my %alliance_data = (
        date_stamp                 => DateTime->now,
        space_station_count         => 0,
        influence                   => 0,
        alliance_id                 => $alliance->id,
        alliance_name               => $alliance->name,
        );
    my $empires = $empire_logs->search({alliance_id => $alliance->id});
    while ( my $empire = $empires->next) {
      $alliance_data{member_count}++;
      $alliance_data{colony_count}             += $empire->colony_count;
      $alliance_data{space_station_count}      += $empire->space_station_count;
      $alliance_data{influence}                += $empire->influence;
      $alliance_data{population}               += $empire->population;
      $alliance_data{building_count}           += $empire->building_count;
      $alliance_data{average_building_level}   += $empire->average_building_level;
      $alliance_data{defense_success_rate}     += $empire->defense_success_rate;
      $alliance_data{offense_success_rate}     += $empire->offense_success_rate;
      $alliance_data{dirtiest}                 += $empire->dirtiest;
      $alliance_data{spy_count}                += $empire->spy_count;
      $alliance_data{average_empire_size}      += $empire->empire_size;
      $alliance_data{average_university_level} += $empire->university_level;
    }
    if ($alliance_data{member_count}) {
      $alliance_data{average_empire_size}     /= $alliance_data{member_count};
      $alliance_data{average_university_level}/= $alliance_data{member_count};
      $alliance_data{average_building_level}  /= $alliance_data{member_count};
      $alliance_data{offense_success_rate}    /= $alliance_data{member_count};
      $alliance_data{defense_success_rate}    /= $alliance_data{member_count};
    }
    my $log = $logs->search({alliance_id => $alliance->id})->first;
    if (defined $log) {
      if ($alliance_data{member_count}) {
        $log->update(\%alliance_data);
      }
      else {
        $log->delete;
      }
    }
    else {
      $logs->new(\%alliance_data)->insert;
    }
  }
}

sub summarize_empires { 
  out('Summarizing Empires');
  my $logs = $db->resultset('Log::Empire');
  my $empires = $db->resultset('Empire')->search({ id   => {'>' => 1} });
  my $colony_logs = $db->resultset('Log::Colony');
  my %mapping;
  while (my $empire = $empires->next) {
    out($empire->name);
    my %empire_data = (
        date_stamp       => DateTime->now,
        university_level => $empire->university_level,
        empire_id        => $empire->id,
        empire_name      => $empire->name,
        alliance_id      => $empire->alliance_id,
        space_station_count => 0,
        influence        => 0,
        );
    my %map_data = (
        empire_id        => $empire->id,
        empire_name      => $empire->name,
        alliance_id      => $empire->alliance_id,
        home_id          => $empire->home_planet_id,
    );
    if ($empire->alliance_id) {
      $empire_data{alliance_name} = $empire->alliance->name;
      $map_data{alliance_name}    = $empire->alliance->name;
    }
    else {
      $empire_data{alliance_name} = undef;
      $map_data{alliance_id}   = 0;
      $map_data{alliance_name} = "Neutral";
    }
    my @map_colonies;
    my $colonies = $colony_logs->search({empire_id => $empire->id});
    while ( my $colony = $colonies->next) {
      if ($colony->is_space_station) {
        $empire_data{influence}                 += $colony->influence;
        $empire_data{space_station_count}++;
        my %map_col = (
          type => "SS",
          x    => $colony->x,
          y    => $colony->y,
          zone => $colony->zone,
          name => "",
        );
        push @map_colonies, \%map_col;
      }
      else {
        $empire_data{colony_count}++;
        $empire_data{population}                += $colony->population;
        $empire_data{population_delta}          += $colony->population_delta;
        $empire_data{building_count}            += $colony->building_count;
        $empire_data{average_building_level}    += $colony->average_building_level;
        $empire_data{highest_building_level}    =  $colony->highest_building_level if ($colony->highest_building_level > $empire_data{highest_building_level});
        $empire_data{food_hour}                 += $colony->food_hour;
        $empire_data{ore_hour}                  += $colony->ore_hour;
        $empire_data{energy_hour}               += $colony->energy_hour;
        $empire_data{water_hour}                += $colony->water_hour;
        $empire_data{waste_hour}                += $colony->waste_hour;
        $empire_data{happiness_hour}            += $colony->happiness_hour;
        $empire_data{defense_success_rate}      += $colony->defense_success_rate;
        $empire_data{defense_success_rate_delta}+= $colony->defense_success_rate_delta;
        $empire_data{offense_success_rate}      += $colony->offense_success_rate;
        $empire_data{offense_success_rate_delta}+= $colony->offense_success_rate_delta;
        $empire_data{dirtiest}                  += $colony->dirtiest;
        $empire_data{dirtiest_delta}            += $colony->dirtiest_delta;
        $empire_data{spy_count}                 += $colony->spy_count;
        if ($colony->body_id eq $map_data{home_id}) {
          my %map_col = (
            type => "Cap",
            x    => $colony->x,
            y    => $colony->y,
            zone => $colony->zone,
            name => "",
          );
          push @map_colonies, \%map_col;
        }
      }
    }
    if (scalar @map_colonies > 0) {
      $map_data{bodies} = \@map_colonies;
      %{$mapping{$map_data{empire_id}}} = %map_data;
    }
    if ($empire_data{colony_count}) {
      $empire_data{average_building_level}    = $empire_data{average_building_level} / $empire_data{colony_count};
      $empire_data{offense_success_rate}      = $empire_data{offense_success_rate} / $empire_data{colony_count};
      $empire_data
{defense_success_rate}      = $empire_data{defense_success_rate} / $empire_data{colony_count};
    }
    $empire_data{empire_size} = $empire_data{colony_count} * $empire_data{population};
    my $log = $logs->search({empire_id => $empire->id})->first;
    if (defined $log) {
      $empire_data{colony_count_delta} = $empire_data{colony_count} - $log->colony_count + $log->colony_count_delta;
      $empire_data{empire_size_delta} = ($empire_data{colony_count_delta}) ? $empire_data{colony_count_delta} * $empire_data{population_delta} : $empire_data{population_delta};
      $log->update(\%empire_data);
    }
    else {
      $logs->new(\%empire_data)->insert;
    }
  }
  my $ai = $db->resultset('Empire')->search({ id   => {'<' => 0} });
  out('Summarizing AI for map');
  while (my $empire = $ai->next) {
    my %map_data = (
        empire_id        => $empire->id,
        empire_name      => $empire->name,
        alliance_id      => $empire->id,
        alliance_name    => $empire->name,
        home_id          => $empire->home_planet_id,
    );
    my @map_colonies;
    my $colonies = $db->resultset('Map::Body')->search({ empire_id   => $empire->id});
    while ( my $colony = $colonies->next) {
      my %map_col = (
        x    => $colony->x,
        y    => $colony->y,
        zone => $colony->zone,
        name => $colony->name,
      );
      my $btype = $colony->get_type;
      if ($btype eq "space staion") {
        $map_col{type} = "SS",
      }
      elsif ($colony->id == $map_data{home_id}) {
        $map_col{type} = "Cap",
      }
      else {
        $map_col{type} = "Col",
      }
      push @map_colonies, \%map_col;
    }
    if (scalar @map_colonies > 0) {
      $map_data{bodies} = \@map_colonies;
      %{$mapping{$map_data{empire_id}}} = %map_data;
    }
  }
  return (\%mapping);
}

sub summarize_colonies { 
    out('Summarizing Planets');
    my $logs = $db->resultset('Log::Colony');
    my $planets = $db->resultset('Map::Body')->search({ empire_id   => {'>' => 1} },{order_by => 'name'});
    my $spy_logs = $db->resultset('Log::Spies');
    while (my $planet = $planets->next) {
        out($planet->name);
        my $log = $logs->search({planet_id => $planet->id})->first;
        my %colony_data = (
            date_stamp             => DateTime->now,
            planet_name            => $planet->name,
            building_count         => scalar @{ $planet->building_cache },
            population             => $planet->population,
            population_delta       => (defined $log ? $log->population_delta + $planet->population - $log->population :  $planet->population ),
            average_building_level => $planet->building_avg_level,
            highest_building_level => $planet->building_max_level,
            food_hour              => $planet->food_hour,
            water_hour             => $planet->water_hour,
            waste_hour             => $planet->waste_hour,
            energy_hour            => $planet->energy_hour,
            ore_hour               => $planet->ore_hour,
            happiness_hour         => $planet->happiness_hour,
            empire_id              => $planet->empire_id,
            empire_name            => $planet->empire->name,
            body_id                => $planet->id,
            x                      => $planet->x,
            y                      => $planet->y,
            zone                   => $planet->zone,
        );
        if ($planet->class =~ /Station$/) {
            $colony_data{is_space_station} = 1;
            $colony_data{influence} = $planet->influence_spent;
        }


        my $spies = $spy_logs->search({planet_id => $planet->id});
        while (my $spy = $spies->next) {
          $colony_data{spy_count}++;
            $colony_data{offense_success_rate}          += $spy->offense_success_rate;
            $colony_data{offense_success_rate_delta}    += $spy->offense_success_rate_delta;
            $colony_data{defense_success_rate}          += $spy->defense_success_rate;
            $colony_data{defense_success_rate_delta}    += $spy->defense_success_rate_delta;
            $colony_data{dirtiest}                      += $spy->dirtiest;
            $colony_data{dirtiest_delta}                += $spy->dirtiest_delta;
        }
        $colony_data{offense_success_rate} = ($colony_data{spy_count}) ? $colony_data{offense_success_rate} / $colony_data{spy_count} : 0;
        $colony_data{defense_success_rate} = ($colony_data{spy_count}) ? $colony_data{defense_success_rate} / $colony_data{spy_count} : 0;
        if (defined $log) {
            $log->update(\%colony_data);
        }
        else {
            $colony_data{planet_id}    = $planet->id;
            $logs->new(\%colony_data)->insert;
        }
    }
}

sub output_map {
  my $mapping = shift;
  
#  my $map_txt = JSON->new->utf8->encode($mapping);
#  open(OUT, ">:utf8:", "mapping.json");
#  print OUT $map_txt;
#  close(OUT);
  my %output;
  my $star_map_size = Lacuna->config->get('map_size');
  $output{map} = {
    bounds => $star_map_size,
  };
  for my $emp_id (keys %$mapping) {
    my @info;
    my @data;
    for my $bod (@{$mapping->{$emp_id}->{bodies}}) {
      my $info_str =
        sprintf("%s (%s) -- %s : (%d,%d) [%s]",
          ($bod->{name} ne "") ? $bod->{name} : $mapping->{$emp_id}->{empire_name},
          $mapping->{$emp_id}->{alliance_name},
          $bod->{type},
          $bod->{x},
          $bod->{y},
          $bod->{zone});
      my $data_str = [ $bod->{x}, $bod->{y} ];
      push @info, $info_str;
      push @data, $data_str;
    }
    my $key = $mapping->{$emp_id}->{alliance_id};
    if (defined $output{alliances}->{$key}) {
      push @{$output{alliances}->{$key}->{info}}, @info;
      push @{$output{alliances}->{$key}->{data}}, @data;
    }
    else {
      $output{alliances}->{$key}->{label}       = $mapping->{$emp_id}->{alliance_name};
      $output{alliances}->{$key}->{alliance_id} = $mapping->{$emp_id}->{alliance_id};
      $output{alliances}->{$key}->{info}        = \@info;
      $output{alliances}->{$key}->{data}        = \@data;
    }
  }
  my $json_txt = JSON->new->utf8->encode(\%output);
  out('Write Map To S3');
  my $config = Lacuna->config;
  my $s3 = SOAP::Amazon::S3->new($config->get('access_key'), $config->get('secret_key'), { RaiseError => 1 });
  my $bucket = $s3->bucket($config->get('feeds/bucket'));
  my $object = $bucket->putobject('starmap.json', $json_txt, { 'Content-Type' => 'application/json; charset=utf-8' });
  $object->acl('public');
}

# UTILITIES

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


