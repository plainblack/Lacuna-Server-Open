package Lacuna::DB::Result::Mission;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date commify randint consolidate_items);
use UUID::Tiny ':std';
use Config::JSON;
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);
use feature 'switch';
use List::Util qw(sum);

__PACKAGE__->table('mission');
__PACKAGE__->add_columns(
    mission_file_name       => { data_type => 'varchar', size => 100, is_nullable => 0 },
    zone                    => { data_type => 'varchar', size => 16, is_nullable => 0 },
    date_posted             => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    max_university_level    => { data_type => 'tinyint', is_nullable => 0 },
    scratch                 => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
);

has params => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Config::JSON->new('/data/Lacuna-Mission/missions/'. $self->mission_file_name);
    },
);

sub log {
    my $self = shift;
    my $logs = Lacuna->db->resultset('Lacuna::DB::Result::Log::Mission');
    my $log = $logs->search({filename => $self->mission_file_name},{rows => 1})->single;
    unless (defined $log) {
        $log = $logs->new({filename => $self->mission_file_name})->insert;
    }
    return $log;
}

sub incomplete {
    my $self = shift;
    my $log = $self->log;
    $log->update({ incompletes => $log->incompletes + 1});
    $self->delete;
}

sub complete {
    my ($self, $body) = @_;
    Lacuna->cache->set($self->mission_file_name, $body->empire_id, 1, 60 * 60 * 24 * 30);
    $self->spend_objectives($body);
    $self->add_rewards($body);
    if (randint(0,9) < 5) {
      Lacuna->db->resultset('Lacuna::DB::Result::News')->new({
          zone                => $self->zone,
          headline            => sprintf($self->params->get('network_19_completion'), $body->empire->name),
      })->insert;
    }
    $self->add_next_part;
    my $log = $self->log;
    $log->update({
        completes           => $log->completes + 1,
        complete_uni_level  => $log->complete_uni_level + $body->empire->university_level,
        seconds_to_complete => $log->seconds_to_complete + time() - $self->date_posted->epoch,
    });
    $self->delete;
}

sub skip {
    my ($self, $body) = @_;
    Lacuna->cache->set($self->mission_file_name, $body->empire_id, 1, 60 * 60 * 24 * 30);
    my $log = $self->log;
    $log->update({
        skips           => $log->skips + 1,
        skip_uni_level  => $log->skip_uni_level + $body->empire->university_level,
    });
}

sub add_next_part {
    my $self = shift;
    $self->mission_file_name =~ m/^([a-z0-9\-\_]+)\.((mission)|(part\d+))$/i;
    my ($name, $ext) = ($1, $2);
    if ($ext eq 'mission') {
        $name .= '.part2';
    }
    else {
        $ext =~ m/^part(\d+)$/;
        $name .= '.part'.$1;
    }
    return Lacuna::DB::Result::Mission->initialize($self->zone, $name);
}

sub add_rewards {
    my ($self, $body) = @_;
    my $rewards = $self->params->get('mission_reward');
    # essentia
    if (exists $rewards->{essentia}) {
        $body->empire->add_essentia({
            amount  => $rewards->{essentia}, 
            reason  => 'mission reward',
        });
        $body->empire->update;
    }
    
    # happiness
    if (exists $rewards->{happiness}) {
        $body->add_happiness($rewards->{happiness});
    }

    # resources
    if (exists $rewards->{resources}) {
        foreach my $resource (keys %{$rewards->{resources}}) {
            $body->add_type($resource, $rewards->{resources}{$resource});
        }
    }
    $body->update;

    # glyphs
# Need to restructure glyphs in Missions to account for quantity
    if (exists $rewards->{glyphs}) {
        foreach my $glyph (@{$rewards->{glyphs}}) {
            $body->add_glyph($glyph);
        }
    }

    # ships
    if (exists $rewards->{ships}) {
        foreach my $ship (@{$rewards->{ships}}) {
            $body->ships->new({
                type        => $ship->{type},
                name        => $ship->{name},
                speed       => $ship->{speed} || 0,
                combat      => $ship->{combat} || 0,
                stealth     => $ship->{stealth} || 0,
                hold_size   => $ship->{hold_size} || 0,
                berth_level => $ship->{berth_level} || 1,
                body_id     => $body->id,
                task        => 'Docked',
            })->insert;
        }
    }

    # plans
# Need to restructure plans in Missions to account for quantity
    if (exists $rewards->{plans}) {
        foreach my $plan (@{$rewards->{plans}}) {
            $body->add_plan($plan->{classname}, $plan->{level}, $plan->{extra_build_level});
        }
    }
}

sub spend_objectives {
    my ($self, $body) = @_;
    my $objectives = $self->params->get('mission_objective');
    # essentia
    if (exists $objectives->{essentia}) {
        $body->empire->spend_essentia({
            amount  => $objectives->{essentia},
            reason  => 'mission objective',
        });
        $body->empire->update;
    }
    
    # happiness
    if (exists $objectives->{happiness}) {
        $body->spend_happiness($objectives->{happiness});
    }
    
    # resources
    if (exists $objectives->{resources}) {
        foreach my $resource (keys %{$objectives->{resources}}) {
            $body->spend_type($resource, $objectives->{resources}{$resource});
        }
    }
    $body->update;

    # glyphs
    if (exists $objectives->{glyphs}) {
        foreach my $glyph (@{$objectives->{glyphs}}) {
            $body->use_glyph( $glyph, 1);
        }
    }

    # ships
    if (exists $objectives->{ships}) {
        foreach my $ship (@{$objectives->{ships}}) {
            $body->ships->search(
                {
                    task        => 'Docked',
                    type        => $ship->{type},
                    combat      => {'>=' => $ship->{combat}},
                    speed       => {'>=' => $ship->{speed}},
                    stealth     => {'>=' => $ship->{stealth}},
                    hold_size   => {'>=' => $ship->{hold_size}},
#                    berth_level => {'>=' => $ship->{berth_level}},
                },
                {rows => 1, order_by => 'id'}
                )->single->delete;
        }
    }

    # plans
    if (exists $objectives->{plans}) {
        foreach my $plan (@{$objectives->{plans}}) {
            # Get the lowest level/extra plan that meet the criteria
            my ($plan) = sort {
                        equivalent_halls($a) <=> equivalent_halls($b)
                    }
                grep {
                    $_->class               eq $plan->{classname}
                and $_->level               >= $plan->{level}
                and $_->extra_build_level   >= $plan->{extra_build_level}
            } @{$body->plan_cache};
            $body->delete_one_plan($plan);
        }
    }
}

# Think consolidating this and Dillon Forge into DB::Plan
sub equivalent_halls {
    my ($plan) = @_;

    my $arg_k   = int($plan->extra_build_level / 2 + 0.5);
    my $arg_l   = $plan->level * 2 + $plan->extra_build_level;
    my $arg_m   = ($plan->extra_build_level % 2) ? 0 : $plan->level + $plan->extra_build_level / 2;
    my $halls   = $arg_k * $arg_l + $arg_m;

    return $halls;
}

sub check_objectives {
    my ($self, $body) = @_;
    my $objectives = $self->params->get('mission_objective');
    
    # essentia
    if (exists $objectives->{essentia}) {
        if ($body->empire->essentia < $objectives->{essentia}) {
            confess [1013, 'You do not have the essentia needed to complete this mission.'];
        }
    }
    
    # happiness
    if (exists $objectives->{happiness}) {
        if ($body->happiness < $objectives->{happiness}) {
            confess [1013, 'You do not have the happiness needed to complete this mission.'];
        }
    }
    
    # resources
    if (exists $objectives->{resources}) {
        foreach my $resource (keys %{$objectives->{resources}}) {
            if ($body->type_stored($resource) < $objectives->{resources}{$resource}) {
                confess [1013, 'You do not have the '.$resource.' needed to complete this mission.'];
            }
        }
    }

    # glyphs
    if (exists $objectives->{glyphs}) {
        my %glyphs;
        foreach my $glyph (@{$objectives->{glyphs}}) {
            $glyphs{$glyph}++;
        }
        foreach my $type (keys %glyphs) {
            my $glyph = Lacuna->db->resultset('Lacuna::DB::Result::Glyph')->search({
                type    => $type,
                body_id => $body->id,
            })->single;
            unless (defined($glyph)) {
                confess [ 1002, "You don't have any glyphs of $type."];
            }
            if ($glyph->quantity < $glyphs{$type}) {
                confess [ 1002,
                    "You don't have $glyphs{$type} glyphs of $type, you only have ".$glyph->quantity];
            }
        }
    }

    # ships
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    if (exists $objectives->{ships}) {
        my @ids;
        foreach my $ship (@{$objectives->{ships}}) {
            my $this = $body->ships->search({
                    type        => $ship->{type},
                    combat      => {'>=' => $ship->{combat} || 0},
                    speed       => {'>=' => $ship->{speed} || 0},
                    stealth     => {'>=' => $ship->{stealth} || 0},
                    hold_size   => {'>=' => $ship->{hold_size} || 0},
                    berth_level => {'>=' => $ship->{berth_level} || 0},
                    task        => 'Docked',
                    id          => { 'not in' => \@ids },
                },{
                   rows     =>1,
                   order_by => 'id',
                })->single;
            if (defined $this) {
                push @ids, $this->id;
            }
            else {
                my $ship = $ships->new({type=>$ship->{type}});
                confess [1013, 'You do not have the '.$ship->type_formatted.' needed to complete this mission.'];
            }
        }
    }

    # fleet movement
    if (exists $objectives->{fleet_movement}) {
        my $bodies = Lacuna->db->resultset("Lacuna::DB::Result::Map::Body");
        my $stars = Lacuna->db->resultset("Lacuna::DB::Result::Map::Star");
        my $scratch = $self->scratch || {fleet_movement=>[]};
        foreach my $movement (@{$scratch->{fleet_movement}}) {
            unless (Lacuna->cache->get($movement->{ship_type}.'_arrive_'.$movement->{target_body_id}.$movement->{target_star_id}, $body->empire_id)) {
                my $ship =  $ships->new({type=>$movement->{ship_type}});
                my $target;
                if ($movement->{target_body_id}) {
                    $target = $bodies->find($movement->{target_body_id});
                }
                else {
                    $target = $stars->find($movement->{target_star_id});
                }
                next unless defined $target;
                confess [1013, 'Have not sent '.$ship->type_formatted.' to '.$target->name.' ('.$target->x.','.$target->y.').'];
            }
        }
    }

    # plans
    if (exists $objectives->{plans}) {
        # Count how many plans of each type are needed
        my $requirements;
        foreach my $plan (@{$objectives->{plans}}) {
            $requirements->{$plan->{classname}.'#'.$plan->{level}.'#'.$plan->{extra_build_level}}++;
        }
        foreach my $key (keys %$requirements) {
            my ($class,$level,$extra) = split('#', $key);
            # Get the lowest level/extra plan that meet the criteria
            my @plan = sort {
                    $a->level               <=> $b->level
                ||  $a->extra_build_level   <=> $b->extra_build_level
                }
            grep {
                    $_->class               eq $class
                and $_->level               >= $level
                and $_->extra_build_level   >= $extra
            } @{$body->plan_cache};
            if (not @plan or $requirements->{$key} > sum(map {$_->quantity} @plan)) {
                confess [1013, 'You do not have the '.$class->name.' plan needed to complete this mission.'];
            }
        }
    }

    return 1;
}

sub format_objectives {
    my $self = shift;
    return $self->format_items($self->params->get('mission_objective'), 1);
}

sub format_rewards {
    my $self = shift;
    return $self->format_items($self->params->get('mission_reward'));
}

sub format_items {
  my ($self, $items, $is_objective) = @_;
  my $item_arr;
  my $item_tmp;
    
  # essentia
  push @{$item_arr}, sprintf('%s essentia.', commify($items->{essentia})) if ($items->{essentia});
    
  # happiness
  push @{$item_arr}, sprintf('%s happiness.', commify($items->{happiness})) if ($items->{happiness});
    
  # resources
  foreach my $resource (keys %{ $items->{resources}}) {
    push @{$item_arr}, sprintf('%s %s', commify($items->{resources}{$resource}), $resource);
  }
    
  # glyphs
  undef $item_tmp;
  foreach my $glyph (@{$items->{glyphs}}) {
    push @{$item_tmp}, $glyph.' glyph';
  }
  if (defined($item_tmp)) {
    push @{$item_arr}, @{consolidate_items($item_tmp)};
  }
    
  # ships
  undef $item_tmp;
  my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
  foreach my $stats (@{ $items->{ships}}) {
    my $ship = $ships->new({type=>$stats->{type}});
    my $pattern = $is_objective ? '%s (speed >= %s, stealth >= %s, hold size >= %s, combat >= %s)' : '%s (speed: %s, stealth: %s, hold size: %s, combat: %s)' ;
    push @{$item_tmp},
         sprintf($pattern, $ship->type_formatted, commify($stats->{speed}),
                 commify($stats->{stealth}), commify($stats->{hold_size}), commify($stats->{combat}));
  }
  if (defined($item_tmp)) {
    push @{$item_arr}, @{consolidate_items($item_tmp)};
  }

  # fleet movement
  if ($is_objective && exists $items->{fleet_movement}) {
    undef $item_tmp;
    my $bodies = Lacuna->db->resultset("Lacuna::DB::Result::Map::Body");
    my $stars = Lacuna->db->resultset("Lacuna::DB::Result::Map::Star");
    my $scratch = $self->scratch || {fleet_movement=>[]};
    foreach my $movement (@{$scratch->{fleet_movement}}) {
      my $ship =  $ships->new({type=>$movement->{ship_type}});
      my $target;
      if ($movement->{target_body_id}) {
        $target = $bodies->find($movement->{target_body_id});
      }
      elsif ($movement->{target_star_id}) {
        $target = $stars->find($movement->{target_star_id});
      }
      unless (defined($target)) {
#        warn "fleet movement target not found";
        next;
      }
      push @{$item_tmp}, 'Send '.$ship->type_formatted.' to '.$target->name.' ('.$target->x.','.$target->y.').';
    }
    if (defined($item_tmp)) {
      push @{$item_arr}, @{consolidate_items($item_tmp)};
    }
  }

  # plans
  undef $item_tmp;
  foreach my $stats (@{ $items->{plans}}) {
    my $level = $stats->{level};
    if ($stats->{extra_build_level}) {
      $level .= '+'.$stats->{extra_build_level};
    }
    my $pattern = $is_objective ? '%s (>= %s) plan' : '%s (%s) plan'; 
    push @{$item_tmp}, sprintf($pattern, $stats->{classname}->name, $level);
  }
  if (defined($item_tmp)) {
    push @{$item_arr}, @{consolidate_items($item_tmp)};
  }

  return $item_arr;
}

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_zone_date_posted', fields => ['zone','date_posted']);
}

sub date_posted_formatted {
    my $self = shift;
    return format_date($self->date_posted);
}

sub feed_url {
    my ($class, $zone) = @_;
    my $config = Lacuna->config;
    Lacuna->config->get('feeds/url').$class->feed_filename($zone);
}

sub feed_filename {
    my ($class, $zone) = @_;
    return 'missioncommand/'.create_uuid_as_string(UUID_MD5, $zone.Lacuna->config->get('feeds/bucket')).'.rss';
}

sub initialize {
    my ($class, $zone, $filename) = @_;
    return undef unless (-f '/data/Lacuna-Mission/missions/'.$filename);
    my $mission = Lacuna->db->resultset('Lacuna::DB::Result::Mission')->new({
        zone                => $zone,
        mission_file_name   => $filename,
    });
    $mission->max_university_level($mission->params->get('max_university_level'));
    my $objectives = $mission->params->get('mission_objective');
    if (exists $objectives->{fleet_movement}) {
        my $scratch;
        foreach my $movement (@{$objectives->{fleet_movement}}) {
            if ($movement->{target}{type} eq 'star') {
                push @{$scratch->{fleet_movement}}, {
                    ship_type       => $movement->{ship_type},
                    target_star_id  => $class->find_star_target($movement, $zone),
                }
            }
            else {
                push @{$scratch->{fleet_movement}}, {
                    ship_type       => $movement->{ship_type},
                    target_body_id  => $class->find_body_target($movement, $zone),
                }
            }
        }
        $mission->scratch($scratch);
    }
    $mission->insert;
    my $log = $mission->log;
    $log->update({ offers => $log->offers + 1});
    if (randint(0,9) < 3) {
      Lacuna->db->resultset('Lacuna::DB::Result::News')->new({
          zone                => $mission->zone,
          headline            => $mission->params->get('network_19_headline'),
      })->insert;
    }
    return $mission;
}

sub find_body_target {
    my ($class, $movement, $zone) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({size => { between => $movement->{target}{size}}});
    
    # body type
    given ($movement->{target}{type}) {
        when ('asteroid') { $body = $body->search({ class => { like => 'Lacuna::DB::Result::Map::Body::Asteroid%'} }) };
        when ('habitable') { $body = $body->search({ class => { like => 'Lacuna::DB::Result::Map::Body::Planet::P%'} }) };
        when ('gas_giant') { $body = $body->search({ class => { like => 'Lacuna::DB::Result::Map::Body::Planet::GasGiant%'} }) };
        when ('space_station') { $body = $body->search({ class => { like => 'Lacuna::DB::Result::Map::Body::Station%'} }) };
    }
    
    # zone
    if ($movement->{target}{in_zone}) {
        $body = $body->search({ zone => $zone});
    }
    else {
        $body = $body->search({ zone => { '!=' => $zone }});
    }

    # inhabited
    if ($movement->{target}{inhabited}) {
        $body = $body->search({ empire_id => { '>' => 1}});
        # isolationist
        if ($movement->{target}{isolationist}) {
            $body = $body->search({ is_isolationist => 1 }, { join => 'empire' });
        }
        else {
            $body = $body->search({ is_isolationist => 0 }, { join => 'empire' });
        }
    }
    else {
        $body = $body->search({ empire_id => undef });
    }
    
    return $body->search(undef,{rows => 1, order_by => 'rand()'})->get_column('id')->single;
}

sub find_star_target {
    my ($class, $movement, $zone) = @_;
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star');

    # zone
    if ($movement->{target}{in_zone}) {
        $star = $star->search({ zone => $zone});
    }
    else {
        $star = $star->search({ zone => { '!=' => $zone }});
    }

    # color
    if ($movement->{target}{color} ne 'any') {
        $star = $star->search({ color => $movement->{target}{color} });
    }

    return $star->search(undef,{rows => 1, order_by => 'rand()'})->get_column('id')->single;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
