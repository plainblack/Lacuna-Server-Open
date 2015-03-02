package Lacuna::DB::Result::Mission;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date commify randint consolidate_items);
use UUID::Tiny ':std';
use Config::JSON;
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);
use feature 'switch';
use List::Util qw(sum first);

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
    my $log = $logs->search({filename => $self->mission_file_name})->first;
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
        my $part = $1 + 1;
        $name .= '.part'.$part;
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
    if (exists $rewards->{glyphs}) {
        foreach my $glyph (@{$rewards->{glyphs}}) {
            $body->add_glyph($glyph->{type}, $glyph->{quantity});
        }
    }

    # ships
    if (exists $rewards->{ships}) {
        foreach my $ship (@{$rewards->{ships}}) {
            foreach (1..$ship->{quantity}) {
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
    }

    # plans
    if (exists $rewards->{plans}) {
        foreach my $plan (@{$rewards->{plans}}) {
            $body->add_plan($plan->{classname}, $plan->{level}, $plan->{extra_build_level}, $plan->{quantity});
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
            $body->use_glyph( $glyph->{type}, $glyph->{quantity});
        }
    }

    # ships
    if (exists $objectives->{ships}) {
        my $ship_ref = get_ship_list($body, $objectives->{ships});
        if ($ship_ref->{pass}) {
            eval {
                $body->ships->search( {
                    id => { 'in' => $ship_ref->{id_list} },
                } )->delete;
            };
        }
        else {
#ERROR MESSAGE NEEDED HERE with clean exit.
        }
    }

    # plans
    if (exists $objectives->{plans}) {
        foreach my $plan_obj (@{$objectives->{plans}}) {
            # Sort plans so that lowest level/extra plan that meet the criteria
            my @plans_on_body = sort {
                    equivalent_halls($a) <=> equivalent_halls($b)
                }
                grep {
                    $_->class               eq $plan_obj->{classname}
                and $_->level               >= $plan_obj->{level}
                and $_->extra_build_level   >= $plan_obj->{extra_build_level}
            } @{$body->plan_cache};
            my $del = 0;
            PLAN: for my $plan_on_body (@plans_on_body) {
                last PLAN if $del >= $plan_obj->{quantity};
                my $to_delete = $plan_obj->{quantity} - $del;
                if ($to_delete <= $plan_on_body->quantity) {
                    $body->delete_many_plans($plan_on_body, $to_delete);
                    $del += $to_delete;
                }
                else {
                    $del +=  $plan_on_body->quantity;
                    $body->delete_many_plans($plan_on_body, $plan_on_body->quantity);
                }
            }
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
    
    if ($body->empire->university_level > $self->params->get('max_university_level')) {
            confess [1013, 'Your university level is above the maximum for this mission.'];
    }
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
        my %ghash;
        foreach my $glyph (@{$objectives->{glyphs}}) {
            if($ghash{$glyph->{type}}) {
                $ghash{$glyph->{type}} += $glyph->{quantity};
            }
            else {
                $ghash{$glyph->{type}} = $glyph->{quantity};
            }
            my $glyph_on_body = Lacuna->db->resultset('Lacuna::DB::Result::Glyph')->search({
                type    => $glyph->{type},
                body_id => $body->id,
            })->first;
            unless (defined($glyph_on_body)) {
                confess [ 1002, "You don't have any glyphs of ".$glyph->{type}."."];
            }
            if ($glyph_on_body->quantity < $ghash{$glyph->{type}}) {
                confess [ 1002,
                    "You don't have ".$ghash{$glyph->{type}}.' glyphs of '.$glyph->{type}.', you only have '.$glyph_on_body->quantity.'.'];
            }
        }
    }

    # ships
    if (exists $objectives->{ships}) {
        my $ship_ref = get_ship_list($body, $objectives->{ships});
        unless ($ship_ref->{pass}) {
            confess [1002, sprintf('%s', join("\n", @{$ship_ref->{message}}))];
        }
    }

    # fleet movement
    if (exists $objectives->{fleet_movement}) {
        my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
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
            $requirements->{$plan->{classname}.'#'.$plan->{level}.'#'.$plan->{extra_build_level}} += $plan->{quantity};
        }
        foreach my $key (keys %$requirements) {
            my ($class,$level,$extra) = split('#', $key);
            # Get the lowest level/extra plan that meet the criteria
            my @plans_on_body = sort {
                    $a->level               <=> $b->level
                ||  $a->extra_build_level   <=> $b->extra_build_level
                }
            grep {
                    $_->class               eq $class
                and $_->level               >= $level
                and $_->extra_build_level   >= $extra
            } @{$body->plan_cache};
            if (not @plans_on_body or $requirements->{$key} > sum(map {$_->quantity} @plans_on_body)) {
                confess [1013, 'You do not have the '.$class->name.' plan needed to complete this mission.'];
            }
        }
    }

    return 1;
}

sub get_ship_list {
    my ($body, $ship_obj_arr) = @_;

    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    my @error_msgs;
    my $pass = 1;

    my $total_needed = 0;
    my %ship_obj_hash;
    foreach my $ship_obj (@{$ship_obj_arr}) {
        my $ship_key = sprintf("%s#%05d#%05d#%05d#%05d#%010d#%02d",
                               $ship_obj->{type},
                               $ship_obj->{combat} || 0,
                               $ship_obj->{speed} || 0,
                               $ship_obj->{stealth} || 0,
                               $ship_obj->{hold_size} || 0,
                               $ship_obj->{berth_level} || 0,
                       );
        if ($ship_obj_hash{$ship_key}) {
            $ship_obj_hash{$ship_key}->{quantity} += $ship_obj->{quantity};
        }
        else {
            $ship_obj_hash{$ship_key} = $ship_obj;
        }
        $total_needed += $ship_obj_hash{$ship_key}->{quantity};
    }
# Check if we have enough of any one type
    for my $skey (sort keys %ship_obj_hash) {
        my @ship_q = $body->ships->search({
                             type        => $ship_obj_hash{$skey}->{type},
                             combat      => {'>=' => $ship_obj_hash{$skey}->{combat} || 0},
                             speed       => {'>=' => $ship_obj_hash{$skey}->{speed} || 0},
                             stealth     => {'>=' => $ship_obj_hash{$skey}->{stealth} || 0},
                             hold_size   => {'>=' => $ship_obj_hash{$skey}->{hold_size} || 0},
                             berth_level => {'>=' => $ship_obj_hash{$skey}->{berth_level} || 0},
                             task        => 'Docked',
                          }, {
                              rows     => $total_needed,
                              order_by => [ 'name', 'id' ],
                          });
        if (scalar @ship_q < $ship_obj_hash{$skey}->{quantity}) {
            $pass = 0;
            my $ship = $ships->new({type=> $ship_obj_hash{$skey}->{type} });
            push @error_msgs,
                sprintf("Need %d of %s (speed >= %s, stealth >= %s, hold size >= %s, combat >= %s, berth >= %s)",
                        $ship_obj_hash{$skey}->{quantity},
                        $ship->type_formatted,
                        $ship_obj_hash{$skey}->{speed} || 0,
                        $ship_obj_hash{$skey}->{stealth} || 0,
                        $ship_obj_hash{$skey}->{hold_size} || 0,
                        $ship_obj_hash{$skey}->{combat} || 0,
                        $ship_obj_hash{$skey}->{berth_level} || 0);
        }
        else {
            $ship_obj_hash{$skey}->{ship_ref} = \@ship_q;
            $ship_obj_hash{$skey}->{total_found} = scalar @ship_q;
        }
    }
    my @id_list;
    if ($pass) {
        while(1) {
            my $skey = first {defined($_)} sort { $ship_obj_hash{$a}->{total_found} - $ship_obj_hash{$a}->{quantity} <=>
                                 $ship_obj_hash{$b}->{total_found} - $ship_obj_hash{$b}->{quantity} } keys %ship_obj_hash;
            my @temp_id;
            for my $ship (@{$ship_obj_hash{$skey}->{ship_ref}}) {
                my $id = $ship->id;
                if ( (scalar @temp_id < $ship_obj_hash{$skey}->{quantity}) and (not grep {$id == $_} @id_list ) ){
                    push @temp_id, $id
                }
            }
            delete $ship_obj_hash{$skey};
            push @id_list, @temp_id;
            for my $lkey (keys %ship_obj_hash) {
                my @new_ship_q;
                for my $elem (@{$ship_obj_hash{$lkey}->{ship_ref}}) {
                    push @new_ship_q, $elem unless (grep { $elem->id == $_} @temp_id);
                }
                $ship_obj_hash{$lkey}->{ship_ref} = \@new_ship_q;
            }
            last unless (%ship_obj_hash);
        }
        if ($total_needed > scalar @id_list) {
            $pass = 0;
            push @error_msgs,
                sprintf("Total qualifying ships, came up short.");
        }
    }

    return {
        pass => $pass,
        message => \@error_msgs,
        id_list => \@id_list,
    };
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
    foreach my $glyph (@{$items->{glyphs}}) {
        my $plural = $glyph->{quantity} > 1 ? "s" : "";
        push @{$item_arr}, sprintf('%s %s glyph%s', commify($glyph->{quantity}), $glyph->{type}, $plural);
    }
    
    # ships
    undef $item_tmp;
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    foreach my $stats (@{ $items->{ships}}) {
        my $ship = $ships->new({type=>$stats->{type}});
        my $pattern = $is_objective ?
                      '%s (speed >= %s, stealth >= %s, hold size >= %s, combat >= %s, berth >= %s)' : '%s (speed: %s, stealth: %s, hold size: %s, combat: %s, berth: %s)' ;
        push @{$item_tmp},
             (sprintf($pattern, $ship->type_formatted, commify($stats->{speed}),
                 commify($stats->{stealth}), commify($stats->{hold_size}), commify($stats->{combat}), $stats->{berth_level})) x $stats->{quantity};
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
        my $plural = $stats->{quantity} > 1 ? "s" : "";
        my $pattern = $is_objective ? '%s %s (>= %s) plan%s' : '%s %s level %s plan%s'; 
        push @{$item_arr}, sprintf($pattern, commify($stats->{quantity}), $stats->{classname}->name, $level, $plural);
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
    
    return $body->search(undef,{order_by => 'rand()'})->get_column('id')->first;
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

    return $star->search(undef,{ order_by => 'rand()'})->get_column('id')->first;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
