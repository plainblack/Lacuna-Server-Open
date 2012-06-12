package Lacuna::RPC::Building::SpacePort;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use Lacuna::Util qw(format_date);
use Data::Dumper;

use feature "switch";

sub app_url {
    return '/spaceport';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::SpacePort';
}

sub find_target {
    my ($self, $target_params) = @_;
    unless (ref $target_params eq 'HASH') {
        confess [-32602, 'The target parameter should be a hash reference. For example { "star_id" : 9999 }.'];
    }
    my $target;
    if (exists $target_params->{star_id}) {
        $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($target_params->{star_id});
    }
    elsif (exists $target_params->{star_name}) {
        $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({ name => $target_params->{star_name} })->first;
    }
    if (exists $target_params->{body_id}) {
        $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target_params->{body_id});
    }
    elsif (exists $target_params->{body_name}) {
        $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({ name => $target_params->{body_name} })->first;
    }
    elsif (exists $target_params->{x}) {
        $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({ x => $target_params->{x}, y => $target_params->{y} })->first;
        unless (defined $target) {
            $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({ x => $target_params->{x}, y => $target_params->{y} })->first;
        }
    }
    unless (defined $target) {
        confess [ 1002, 'Could not find the target.', $target];    
    }
    return $target;
}


# Get incoming fleets for a target
sub get_incoming_for {
    my ($self, $session_id, $target_params, $paging, $filter, $sort) = @_;

    $paging = $self->_fleet_paging_options( (defined $paging && ref $paging eq 'HASH') ? $paging : {} );
    $filter = $self->_fleet_filter_options( (defined $filter && ref $filter eq 'HASH') ? $filter : {} );
    $sort   = $self->_fleet_sort_options( $sort // 'type' );

    my $attrs = {
        order_by    => $sort,
        prefetch    => { body => 'empire' },
    };
    $attrs->{rows} = $paging->{items_per_page} if ( defined $paging->{items_per_page} );
    $attrs->{page} = $paging->{page_number} if ( defined $paging->{page_number} );

    my $empire  = $self->get_empire_by_session($session_id);
    my $target  = $self->find_target($target_params);

    my $incoming_rs = Lacuna->db->resultset('Fleet')->search($filter, $attrs);
    $incoming_rs = $incoming_rs->search({
        task        => 'Travelling',
        direction   => 'out',
    });

    if ($empire->alliance_id) {
        $incoming_rs = $incoming_rs->search({
            -or => {
                'body.empire_id'  => $empire->id,
                'empire.alliance_id' => $empire->alliance_id,
            }
        });
    }
    else {
        $incoming_rs = $incoming_rs->search({
            'body.empire_id' => $empire->id,
        });
    }
    if ($target->isa('Lacuna::DB::Result::Map::Star')) {
        $incoming_rs = $incoming_rs->search({ foreign_star_id => $target->id });
    }
    else {
        $incoming_rs = $incoming_rs->search({ foreign_body_id => $target->id });
    }
    my @incoming;
    while (my $fleet = $incoming_rs->next) {
        push @incoming, $fleet->get_status;
    }
        
    my %out = (
        status      => $self->format_status($empire),
        incoming    => \@incoming,
    );

    return \%out;
}




# Get a list of fleets that can be sent to a target
sub get_fleets_for {
    my ($self, $session_id, $body_id, $target_params) = @_;

    my $empire  = $self->get_empire_by_session($session_id);
    my $body    = $self->get_body($empire, $body_id);
    my $target  = $self->find_target($target_params);
    my $fleets  = Lacuna->db->resultset('Lacuna::DB::Result::Fleet');
    
    my @incoming;
    my $incoming_rs = $fleets->search({
        task                => 'Travelling', 
        direction           => 'out',
        'body.empire_id'    => $empire->id,
        },{ 
        join => 'body',
    });
    if ($target->isa('Lacuna::DB::Result::Map::Star')) {
        $incoming_rs = $incoming_rs->search({foreign_star_id => $target->id});
    }
    else {
        $incoming_rs = $incoming_rs->search({foreign_body_id => $target->id});
    }
    while (my $ship = $incoming_rs->next) {
        $ship->body($body) if ($ship->body_id == $body->id);
        push @incoming, $ship->get_status;
    }
    
    my $max_berth = $body->max_berth;

    my @unavailable;
    my @available;
    my $available_rs = $fleets->search( {task => 'Docked',
                                        body_id=>$body->id });
    while (my $ship = $available_rs->next) {
      $ship->body($body);
      eval{ 
          $ship->can_send_to_target($target);
          confess [1009, "Sitters cannot send this type of ship."] if $empire->current_session->is_sitter and not $ship->sitter_can_send;
      };
      my $reason = $@;
      if ($reason) {
        push @unavailable, { ship => $ship->get_status, reason => $reason };
        next;
      }
      if ($ship->berth_level > $max_berth) {
        $reason = [ 1009, 'Max Berth Level to send from this planet is '.$max_berth ];
        push @unavailable, { ship => $ship->get_status, reason => $reason };
        next;
      }
      $ship->body($body);
      push @available, $ship->get_status($target);
    }
    
    my $max_ships = Lacuna->config->get('ships_per_fleet') || 600;

    my %out = (
        status              => $self->format_status($session, $body),
        incoming            => \@incoming,
        available           => \@available,
        unavailable         => \@unavailable,
        fleet_send_limit    => $max_ships,
    );
    
    unless ($target->isa('Lacuna::DB::Result::Map::Star')) {
        my @orbiting;
        my $orbiting_rs = $fleets->search({task => [qw(Defend Orbiting)], body_id => $body->id, foreign_body_id => $target->id });
        while (my $ship = $orbiting_rs->next) {
            $ship->body($body);
            eval{ $ship->can_recall() };
                my $reason = $@;
                if ($reason) {
                    push @unavailable, { ship => $ship->get_status, reason => $reason };
                    next;
                }
            $ship->body($body);
            push @orbiting, $ship->get_status($target);
        }
        $out{orbiting} = \@orbiting;
    }

    if ($target->isa('Lacuna::DB::Result::Map::Body::Asteroid')) {
        my $platforms = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->search({asteroid_id => $target->id});
        while (my $platform = $platforms->next) {
            my $empire = $platform->planet->empire;
            if (defined $empire) {
                push @{$out{mining_platforms}}, {
                    empire_id   => $empire->id,
                    empire_name => $empire->name,
                };
            }
            else {
                $platform->delete;
            }
        }
    }
    if ( $target->isa('Lacuna::DB::Result::Map::Body::Asteroid') ||
         $target->isa('Lacuna::DB::Result::Map::Body::Planet') ) {
        my $excavators = Lacuna->db->resultset('Lacuna::DB::Result::Excavators')->search({body_id => $target->id});
        while (my $excav = $excavators->next) {
            my $empire = $excav->planet->empire;
            if (defined $empire) {
                push @{$out{excavators}}, {
                  empire_id   => $empire->id,
                  empire_name => $empire->name,
                };
            }
            else {
                $excav->delete;
            }
        }
    }
    
    return \%out;
}

sub send_ship {
    my ($self, $session_id, $ship_id, $target_params) = @_;
    my $session  = $self->get_session({session_id => $session_id});
    my $empire   = $session->current_empire;
    my $target = $self->find_target($target_params);
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, 'Could not locate that ship.'];
    }
    unless ($ship->body->empire_id == $empire->id) {
        confess [1010, 'You do not own that ship.'];
    }
    my $body = $ship->body;
    $body->empire($empire);
    $ship->can_send_to_target($target);
    if ($ship->hostile_action) {
        $empire->current_session->check_captcha;
    }
    confess [1009, "Sitters cannot send this type of ship."] if $empire->current_session->is_sitter and not $ship->sitter_can_send;
    $ship->send(target => $target);
    $body->add_to_neutral_entry($ship->combat);
    return {
        ship    => $ship->get_status,
        status  => $self->format_status($session),
    }
}

sub find_arrival {
    my ($self, $arrival_params) = @_;

    my $now     = DateTime->now;
    my $year = $arrival_params->{year} ? $arrival_params->{year} : $now->year;
    my $month = $arrival_params->{month} ? $arrival_params->{month} : $now->month;

    if ($month < 1 or 12 < $month) {
        confess [1002, 'Invalid month'];
    }

    my $mon_end = DateTime->last_day_of_month(year => $year, month => $month);
    my $day     = $arrival_params->{day};
    my $hour    = $arrival_params->{hour};
    my $minute  = $arrival_params->{minute};
    my $second  = $arrival_params->{second};

    if (not defined $day or $day < 1 or $day > $mon_end->day) {
        confess [1009, "Invalid day. [$day][".Dumper($arrival_params)."]"];
    }
    if (not defined $hour or $hour != int($hour) or $hour < 0 or $hour > 23) {
        confess [1002, 'Invalid hour.'];
    }
    if (not defined $minute or $minute != int($minute) or $minute < 0 or $minute > 59) {
        confess [1002, 'Invalid minute.'];
    }
    if (not defined $second or $second != 0 and $second != 15 and $second != 30 and $second != 45) {
        confess [1002, 'Invalid second. Must be 0, 15, 30 or 45'];
    }
    if ($day < $now->day and $month == $now->month) {
        # Then it must be a day next month
        $mon_end->add( days => $day);
        $year    = $mon_end->year;
        $month   = $mon_end->month;
    }
    my $arrival = DateTime->new(
        year    => $year,
        month   => $month,
        day     => $day,
        hour    => $hour,
        minute  => $minute,
        second  => $second,
    );
    return $arrival;
}

sub send_ship_types {
    my ($self, $session_id, $body_id, $target_params, $type_params, $arrival_params) = @_;

    my $session  = $self->get_session({session_id => $session_id, body_id => $body_id});
    my $empire   = $session->current_empire;
    my $body     = $session->current_body;
    my $target  = $self->find_target($target_params);
    my $arrival;
    if ($arrival_params->{earliest}) {
    }
    else {
        $arrival_params->{seconds} = 0 unless (defined $arrival_params->{seconds});
        $arrival = $self->find_arrival($arrival_params);
    }

    # calculate the total ships before the expense of any database operations.
    my $total_ships = 0;
    map {$total_ships += $_->{quantity}} @$type_params;
    my $max_ships = Lacuna->config->get('ships_per_fleet') || 600;
    if ($total_ships > $max_ships) {
        confess [1009, sprintf("Too many ships for a fleet, number must be less than or equal to %d.", $max_ships)];
    }

    my $ship_ref;
    my $do_captcha_check = 0;
    my $ag_chk = 0;
    my @ag_list = ("sweeper","snark","snark2","snark3",
                   "observatory_seeker","spaceport_seeker","security_ministry_seeker",
                   "scanner","surveyor","detonator","bleeder","thud",
                   "scow","scow_large","scow_fast","scow_mega");
    foreach my $type_param (@$type_params) {
        foreach my $arg (qw(speed stealth combat quantity)) {
            confess [1002, "$arg cannot be negative."] if $type_param->{$arg} < 0;
            confess [1002, "$arg must be an integer."] if $type_param->{$arg} != int($type_param->{$arg});
        }
        my $type        = $type_param->{type};
        my $quantity    = $type_param->{quantity};
        confess [1009, "You must send at least one ship"] if ($quantity < 1);
        confess [1009, "Cannot send more than one excavator"] if ($type eq 'excavator' and $quantity > 1);
        confess [1009, "Cannot send more than one supply pod"] if ($type =~ /supply_pod/ and $quantity > 1);

        my $max_berth = $body->max_berth;
        unless ($max_berth) {
            $max_berth = 1;
        }
        my $ships_rs    = Lacuna->db->resultset('Ships')->search({
            body_id => $body->id,
            task    => 'Docked',
            type    => $type,
            berth_level => {'<=' => $max_berth },
        });
        # handle optional parameters
        $ships_rs = $ships_rs->search({ speed =>   $type_param->{speed}}) if defined $type_param->{speed};
        $ships_rs = $ships_rs->search({ stealth => $type_param->{stealth}}) if defined $type_param->{stealth};
        $ships_rs = $ships_rs->search({ combat =>  $type_param->{combat}}) if defined $type_param->{combat};
        $ships_rs = $ships_rs->search({ name =>    $type_param->{name}}) if defined $type_param->{name};
        if ($ships_rs->count < $quantity) {
            confess [1009, "Cannot find $quantity of $type ships."];
        }
        if (grep { $type eq $_ } @ag_list) {
            $ag_chk += $quantity;
        }
        my @ships = $ships_rs->search( undef,
                                      {order_by => 'speed', rows => $quantity }
                                      );
        my $ship = $ships[0]; #Need to grab slowest ship
        confess [1009, "Sitters cannot send this type of ship."] if $session->is_sitter and not $ship->sitter_can_send;
        # We only need to check one of the ships
        $ship->can_send_to_target($target);

#Check speed of ship.  If it can not make it to the target in time, fail
#If time to target is longer than 60 days, fail.
        my $seconds_to_target = $ship->calculate_travel_time($target);
        my $earliest = DateTime->now->add(seconds=>$seconds_to_target);
        if ($arrival_params->{earliest}) {
            $arrival = $earliest;
        }
        elsif ($earliest > $arrival) {
            confess [1009, "Cannot set a speed earlier than possible arrival time."];
        }
        my $two_months  = DateTime->now->add(days=>60);
        if ($arrival > $two_months) {
            confess [1009, "Cannot send a ship that will take longer than 60 days to arrive."];
        }

        if (not $do_captcha_check and $ship->hostile_action) {
            $do_captcha_check = 1;
        }
        foreach my $ship (@ships) {
            $ship_ref->{$ship->id} = $ship;
        }
    }
    if ($do_captcha_check) {
        $empire->current_session->check_captcha;
    }
    # If we get here without exceptions, then all ships can be sent

# Create attack_group
    my $cnt = 0;
    my %ag_hash = map { $_ => $cnt++ } @ag_list;
    my $attack_group = {
        speed       => 50_000,
        stealth     => 50_000,
        hold_size   => 0,
        combat      => 0,
        number_of_docks => 0,
    };
    my $payload;
    $ag_chk = 0 if ($target->isa('Lacuna::DB::Result::Map::Star'));
    
    foreach my $ship (values %$ship_ref) {
        if ($ag_chk > 1 and grep { $ship->type eq $_ } @ag_list) {
            my $sort_val = $ag_hash{$ship->type};
            if ($ship->speed < $attack_group->{speed}) {
                $attack_group->{speed} = $ship->speed;
            }
            if ($ship->speed < $attack_group->{stealth}) {
                $attack_group->{stealth} = $ship->stealth;
            }
            $attack_group->{combat} += $ship->combat;
            $attack_group->{hold_size} += $ship->hold_size; #This really is only good for scows
            $attack_group->{number_of_docks}++;
            my $key = sprintf("%02d:%s:%05d:%05d:%05d:%09d",
                              $sort_val,
                              $ship->type, 
                              $ship->combat, 
                              $ship->speed, 
                              $ship->stealth, 
                              $ship->hold_size);
            if ($payload->{fleet}->{$key}) {
                $payload->{fleet}->{$key}->{quantity}++;
            }
            else {
                $payload->{fleet}->{$key} = {
                    type      => $ship->type, 
                    name      => $ship->name,
                    speed     => $ship->speed, 
                    combat    => $ship->combat, 
                    stealth   => $ship->stealth, 
                    hold_size => $ship->hold_size,
                    target_building => $ship->target_building,
                    damage_taken => 0,
                    quantity  => 1,
                };
            }
            $ship->delete;
        }
        else {
            my $distance = $body->calculate_distance_to_target($target);
            my $transit_time = $arrival->subtract_datetime_absolute(DateTime->now)->seconds;
            my $fleet_speed = int( $distance / ($transit_time/3600) + 0.5);

            $ship->fleet_speed($fleet_speed);
            $ship->send(target => $target, arrival => $arrival);
            $body->add_to_neutral_entry($ship->combat);
        }
    }
    if ($attack_group->{number_of_docks} > 0) {
        my $distance = $body->calculate_distance_to_target($target);
        my $transit_time = $arrival->subtract_datetime_absolute(DateTime->now)->seconds;
        my $fleet_speed = int( $distance / ($transit_time/3600) + 0.5);
        my $ag = $body->ships->new({
            type            => "attack_group",
            name            => "Attack Group SP",
            shipyard_id     => "23",
            speed           => $attack_group->{speed},
            combat          => $attack_group->{combat},
            stealth         => $attack_group->{stealth},
            hold_size       => $attack_group->{hold_size},
            date_available  => DateTime->now,
            date_started    => DateTime->now,
            fleet_speed     => $fleet_speed,
            berth_level     => 1,
            body_id         => $body->id,
            task            => 'Docked',
            number_of_docks => $attack_group->{number_of_docks},
          })->insert;
        $ag->send(target => $target, arrival => $arrival, payload => $payload);
        $body->add_to_neutral_entry($attack_group->{combat});
    }
    return $self->get_fleet_for($session_id, $body_id, $target_params);
}

sub send_fleet {
  my ($self, $session_id, $ship_ids, $target_params, $set_speed) = @_;
  $set_speed //= 0;
  my $session  = $self->get_session({session_id => $session_id});
  my $empire   = $session->current_empire;
  my $target = $self->find_target($target_params);
  my $max_ships = Lacuna->config->get('ships_per_fleet') || 600;
  if (@$ship_ids > $max_ships) {
      confess [1009, 'Too many ships for a fleet.'];
  }
  my @fleet;
  my $speed = 999999999;

  my $excavator = 0;
  my $supply_pod = 0;
  for my $ship_id (@$ship_ids) {
      my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
      unless (defined $ship) {
          confess [1002, 'Could not locate that ship.'];
      }
      unless ($ship->body->empire_id == $empire->id) {
          confess [1010, 'You do not own that ship.'];
      }
      $excavator++ if ($ship->type eq 'excavator');
      $supply_pod++ if ($ship->type =~ /supply_pod/);
      $speed = $ship->speed if ( $speed > $ship->speed );
      push @fleet, $ship_id;
  }

  my $tmp_ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($fleet[0]);
  my $body = $tmp_ship->body;
  my $distance = $body->calculate_distance_to_target($target);
  my $max_speed = $distance  * 12;  # Minimum time to arrive is five minutes
  my $min_speed = int($distance/1440 + 0.5); # Max time to arrive is two months
  $min_speed = 1 if $min_speed < 1;

  unless ($excavator <= 1) {
      confess [1010, 'Only one Excavator may be sent to a body by this empire.'];
  }
  unless ($set_speed <= $speed) {
      confess [1009, 'Set speed cannot exceed the speed of the slowest ship.'];
  }
  unless ($set_speed >= 0) {
      confess [1009, 'Set speed cannot be less than zero.'];
  }
#If time to target is longer than 60 days, fail.
  $speed = $set_speed if ($set_speed > 0 && $set_speed < $speed);
  $speed = $max_speed if ($speed > $max_speed);

  unless ($speed >= $min_speed) {
      confess [1009, 'Set speed cannot be set so that ships arrive after 60 days.'];
  }

  my @ret;
  my $captcha_check = 1;

# Check captcha if needed
# Create attack_group

  for my $ship_id (@fleet) {
      my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
      my $body = $ship->body;
      $body->empire($empire);
      $ship->can_send_to_target($target);
      if ($captcha_check && $ship->hostile_action ) {
          $empire->current_session->check_captcha;
          $captcha_check = 0;
      }
      confess [1009, "Sitters cannot send this type of ship."] if $empire->current_session->is_sitter and not $ship->sitter_can_send;
      $body->add_to_neutral_entry($ship->combat);
      $ship->fleet_speed($speed);
      $ship->send(target => $target);
      push @ret, {
          ship    => $ship->get_status,
      }
  }
  return {
      fleet  => \@ret,
      status  => $self->format_status($session),
  };
}

sub recall_ship {
  my ($self, $session_id, $building_id, $ship_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, 'Could not locate that ship.'];
    }
    unless ($ship->body->empire_id == $empire->id) {
        confess [1010, 'You do not own that ship.'];
    }
    my $body = $building->body;
    $body->empire($empire);
    $ship->can_recall();

    $ship->fleet_speed(0);

    my $target = $self->find_target({body_id => $ship->foreign_body_id});
    $ship->send(
    target    => $target,
    direction  => 'in',
  );
    $ship->body->update;
    return {
        ship    => $ship->get_status,
        status  => $self->format_status($session),
    }
}

sub recall_all {
  my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $body = $building->body;
    my @ships = $body->ships_orbiting->search(undef)->all;
    my @ret;
    for my $ship (@ships) {
        unless (defined $ship) {
            confess [1002, 'Could not locate that ship.'];
        }
        unless ($ship->body->empire_id == $empire->id) {
            confess [1010, 'You do not own that ship.'];
        }
        $body->empire($empire);
        $ship->can_recall();
        $ship->fleet_speed(0);

        my $target = $self->find_target({body_id => $ship->foreign_body_id});
        $ship->send(
            target    => $target,
            direction  => 'in',
        );
        $ship->body->update;
    push @ret, {
      ship    => $ship->get_status,
    }
    }
    return {
    ships  => \@ret,
        status  => $self->format_status($session),
    }
}

sub prepare_send_spies {
    my ($self, $session_id, $on_body_id, $to_body_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, body_id => $on_body_id});
    my $empire   = $session->current_empire;
    my $on_body  = $session->current_body;
    if ($on_body_id == $to_body_id) {
        confess [1013, "Cannot send spies to one self."];
    }
    my $to_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($to_body_id);

    unless ($to_body->empire_id) {
        confess [1009, "Cannot send spies to an uninhabited body."];
    }
    if ($to_body->empire->is_isolationist) {
        confess [ 1013, sprintf('%s is an isolationist empire, and must be left alone.',$to_body->empire->name)];
    }

    unless ($on_body->empire_id == $to_body->empire_id) {
        $empire->current_session->check_captcha;
    }
    
    my $max_berth = $on_body->max_berth;
    unless ($max_berth) {
        $max_berth = 1;
    }

    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {type => { in => [qw(spy_pod cargo_ship smuggler_ship dory spy_shuttle barge)]},
         task=>'Docked', body_id => $on_body_id,
         berth_level => {'<=' => $max_berth } },
        {order_by => 'name', rows=>100}
    );
    my @ships;
    while (my $ship = $ships->next) {
        push @ships, $ship->get_status($to_body);
    }

    my $dt_parser = Lacuna->db->storage->datetime_parser;
    my $now = $dt_parser->format_datetime( DateTime->now );

    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
        {
            on_body_id => $on_body->id, 
            empire_id => $empire->id,
            -or => [
                task => { in => [ 'Idle', 'Counter Espionage' ], },
                -and => [
                    task => { in => [ 'Unconscious', 'Debriefing' ], },
                    available_on => { '<' => $now }, 
                ],
            ],
        },
        {
            # match the order_by in L::RPC::B::Intelligence::view_spies
            order_by => {
                -asc => [ qw/name id/ ],
            }
        },
    );
    my @spies;
    while (my $spy = $spies->next) {
        $spy->on_body($on_body);
        if ($spy->is_available) {
            push @spies, $spy->get_status;
        }
        last if (scalar @spies >= 100);
    }
    undef $spies;

    return {
        status  => $self->format_status($session),
        ships   => \@ships,
        spies   => \@spies,
    };
}

sub send_spies {
    my ($self, $session_id, $on_body_id, $to_body_id, $ship_id, $spy_ids) = @_;
    my $session  = $self->get_session({session_id => $session_id, body_id => $on_body_id});
    my $empire   = $session->current_empire;
    if ($on_body_id == $to_body_id) {
        confess [1013, "Cannot send spies to one self."];
    }
    my $on_body = $session->current_body();
    my $to_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($to_body_id);
    
    # make sure it's a valid target
    unless ($to_body->empire_id) {
        confess [ 1009, 'Cannot send spies to an uninhabited body.'];
    }
    if ($to_body->empire->is_isolationist) {
        confess [ 1013, sprintf('%s is an isolationist empire, and must be left alone.',$to_body->empire->name)];
    }

    unless ($on_body->empire_id == $to_body->empire_id) {
        $empire->current_session->check_captcha;
    }

    # get the ship
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, "Ship not found."];
    }
    unless ($ship->is_available) {
        confess [1010, "That ship is not available."];
    }
    my $max_berth = $on_body->max_berth;
    unless ($ship->berth_level <= $max_berth) {
        confess [1010, "Your spaceport level is not high enough to support a ship with a Berth Level of ".$ship->berth_level."."];
    }

    # check size
    unless (scalar(@{$spy_ids})) {
        confess [1013, "You can't send a ship with no spies."];
    }
    
    if ($ship->type eq 'spy_pod' && scalar(@{$spy_ids}) == 1) {
        # we're ok
    }
    elsif ($ship->type eq 'spy_shuttle' && scalar(@{$spy_ids}) <= 4) {
        # we're ok
    }
    elsif ($ship->hold_size <= (scalar(@{$spy_ids}) * 350)) {
        confess [1010, "The ship cannot hold the spies selected."];
    }
    
    # get a spies
    my @ids_sent;
    my @ids_not_sent;
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies');
    foreach my $id (@{$spy_ids}) {
        my $spy = $spies->find($id);
        if ($spy->is_available and $spy->on_body_id == $on_body_id) {
            if ($spy->empire_id == $empire->id) {
                my $arrives = DateTime->now->add(seconds=>$ship->calculate_travel_time($to_body));
                push @ids_sent, $spy->id;
                $spy->send($to_body->id, $arrives)->update;
            }
            else {
                push @ids_not_sent, $spy->id;
            }
        }
        else {
            push @ids_not_sent, $spy->id;
        }
    }
    if (scalar @ids_sent) {
        # send it
        $ship->send(
            target      => $to_body,
            payload     => {spies => \@ids_sent }, # add the spies to the payload when we send, otherwise they'll get added again
        );
    }
    return {
        ship            => $ship->get_status,
        spies_sent      => \@ids_sent,
        spies_not_sent  => \@ids_not_sent,
        status          => $self->format_status($session, $on_body)
    };
}

sub prepare_fetch_spies {
    my ($self, $session_id, $on_body_id, $to_body_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, body_id => $to_body_id});
    my $empire   = $session->current_empire;
    if ($on_body_id == $to_body_id) {
        confess [1013, "Cannot fetch spies to one self."];
    }
    my $to_body = $session->current_body;
    my $on_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($on_body_id);
    unless ($on_body->empire_id) {
        confess [1013, "Cannot fetch spies from an uninhabited planet."];
    }

    my $max_berth = $to_body->max_berth;
    unless ($max_berth) {
        $max_berth = 1;
    }

    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {type => { in => [qw(cargo_ship smuggler_ship dory spy_shuttle barge)]},
         task=>'Docked', body_id => $to_body_id,
         berth_level => {'<=' => $max_berth } },
        {order_by => 'name', rows=>100}
    );
    my @ships;
    while (my $ship = $ships->next) {
        push @ships, $ship->get_status($on_body);
    }

    my $dt_parser = Lacuna->db->storage->datetime_parser;
    my $now = $dt_parser->format_datetime( DateTime->now );

    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
        {
            on_body_id => $on_body->id, 
            empire_id => $empire->id,
            -or => [
                task => { in => [ 'Idle', 'Counter Espionage' ], },
                -and => [
                    task => { in => [ 'Unconscious', 'Debriefing' ], },
                    available_on => { '<' => $now }, 
                ],
            ],
        },
        {order_by => 'name'}
    );
    my @spies;
    while (my $spy = $spies->next) {
        $spy->on_body($on_body);
        if ($spy->is_available) {
            push @spies, $spy->get_status;
        }
        last if (scalar @spies >= 100);
    }
    undef $spies;
    
    return {
        status  => $self->format_status($session),
        ships   => \@ships,
        spies   => \@spies,
    };
}

sub fetch_spies {
    my ($self, $session_id, $on_body_id, $to_body_id, $ship_id, $spy_ids) = @_;
    my $session  = $self->get_session({session_id => $session_id, body_id => $to_body_id});
    my $empire   = $session->current_empire;
    if ($on_body_id == $to_body_id) {
        confess [1013, "Cannot fetch spies to one self."];
    }
    my $to_body = $session->current_body;
    my $on_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($on_body_id);

    my $max_berth = $to_body->max_berth;

    # get a spies
    my @ids_fetched;
    my @ids_not_fetched;
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies');
    foreach my $id (@{$spy_ids}) {
        my $spy = $spies->find($id);
        if ($spy->on_body_id == $on_body_id) {
            push @ids_fetched, $id;
        }
        else {
            push @ids_not_fetched, $id;
        }
    }

    # get the ship
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, "Ship not found."];
    }
    unless ($ship->is_available || ($ship->can_recall && $ship->foreign_body_id == $on_body_id)) {
        confess [1010, "That ship is not available."];
    }

    unless ($ship->berth_level <= $max_berth) {
        confess [1010, "Your spaceport level is not high enough to support a ship with a Berth Level of ".$ship->berth_level."."];
    }

    unless ($on_body->empire_id) {
        confess [1013, "Cannot fetch spies from an uninhabited planet."];
    }

    unless (scalar(@ids_fetched)) {
        confess [1013, "You can't send a ship to collect no one."];
    }
    
    # check size
    if ($ship->type eq 'spy_shuttle' && scalar(@ids_fetched) <= 4) {
        # we're ok
    }
    elsif ($ship->hold_size <= (scalar(@ids_fetched) * 350)) {
        confess [1013, "The ship cannot hold the spies selected."];
    }
    
    # send it
    $ship->send(
        target      => $on_body,
        payload     => { fetch_spies => \@ids_fetched },
    );

    return {
        ship    => $ship->get_status,
        spies_fetched      => \@ids_fetched,
        spies_not_fetched  => \@ids_not_fetched,
        status  => $self->format_status($session, $to_body),
    };
}



sub view_fleets_travelling {
    my ($self, $session_id, $building_id, $page_number) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my $body = $building->body;
    my @travelling;
    my $fleets = $body->fleets_travelling->search(undef, {rows=>25, page=>$page_number});
    while (my $fleet = $fleets->next) {
        $fleet->body($body);
        push @travelling, $fleet->get_status;
    }
    return {
        status                      => $self->format_status($empire, $body),
        number_of_fleets_travelling => $fleets->pager->total_entries,
        number_of_ships_travelling  => 666, # TODO 
        ships_travelling            => \@travelling,
    };
}

sub _fleet_paging_options {
    my ($self, $paging) = @_;
#    for my $key ( keys %{ $paging } ) {
#        # Throw away bad keys
#        unless ($key ~~ [qw(page_number items_per_page no_paging)]) {
#            delete $paging->{$key};
#            next;
#        }
#    }
    if ($paging->{no_paging}) {
        $paging = {};
    }
    else {
        $paging->{page_number} ||= 1;
        $paging->{items_per_page} ||= 25;
    }
    return $paging;
}

sub _fleet_filter_options {
    my ($self, $filter) = @_;

    # Valid filter options include...
    my $options = {
        task    => [qw(Docked Building Mining Travelling Defend Orbiting),'Waiting On Trade','Supply Chain','Waste Chain'],
        tag     => [qw(Trade Colonization Intelligence Exploration War Mining SupplyChain WasteChain)],
        type    => [SHIP_TYPES],
    };

    # Pull in the list of fleet types by tag
    my %tag;
    for my $type ( SHIP_TYPES ) {
        my $fleet = Lacuna->db->resultset('Lacuna::DB::Result::Fleet')->new({ type => $type });
        for my $tag ( @{$fleet->build_tags} ) {
            push @{ $tag{$tag} }, $type;
        }
    }

    for my $key ( keys %{ $filter } ) {
        # Throw away bad keys
        unless ( $key ~~ [keys %$options] ) {
            delete $filter->{$key};
            next;
        }

        # Throw away bad values
        my $value = $filter->{$key};
        if ( ref($value) eq 'ARRAY' ) {
            @$value = grep { $_ ~~ $options->{$key} } @$value;
        }
        elsif ( ! ref($value) ) {
            delete $filter->{$key} unless ( $value ~~ $options->{$key} );
        }
        else {
            delete $filter->{$key};
        }

        # Convert tags to types (destructive)
        if ( $key eq 'tag' ) {
            if ( ref($value) eq 'ARRAY' ) {
                my @types;
                for my $tag ( @$value ) {
                    push @types, @{ $tag{$tag} };
                }
                my %uniq = map { $_ => 1 } @types;
                $filter->{type} = [ sort keys %uniq ];
            }
            else {
                $filter->{type} = $tag{$value};
            }
            delete $filter->{tag};
        }
    }

    return $filter;
}

sub _fleet_sort_options {
    my ($self, $sort) = @_;

    # return the default if it's not one of the following or is 'name'
    if ( ! $sort || $sort eq 'name' || ! $sort ~~ [qw(type task combat speed stealth)] ) {
        return [ 'type' ];
    }

    # append name to the sort options
    return [ $sort, 'name' ];
}

sub view_all_fleets {
    my ($self, $session_id, $building_id, $paging, $filter, $sort) = @_;

    $paging = $self->_fleet_paging_options( (defined $paging && ref $paging eq 'HASH') ? $paging : {} );
    $filter = $self->_fleet_filter_options( (defined $filter && ref $filter eq 'HASH') ? $filter : {} );
    $sort = $self->_fleet_sort_options( $sort // 'type' );

    my $attrs = {
        order_by => $sort,
    };
    $attrs->{rows} = $paging->{items_per_page} if ( defined $paging->{items_per_page} );
    $attrs->{page} = $paging->{page_number} if ( defined $paging->{page_number} );

    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $body = $building->body;

    my @fleet;
    my $fleets = $body->fleets->search( $filter, $attrs );
    while (my $fleet = $fleets->next) {
        push @fleet, $fleet->get_status;
    }

    return {
        status              => $self->format_status($empire, $body),
        number_of_fleets    => defined $paging->{page_number} ? $fleets->pager->total_entries : $fleets->count,
        fleets              => \@fleet,
    };
}

# View incoming fleets (not own returning fleets)
sub view_incoming_fleets {
    my ($self, $session_id, $building_id, $page_number) = @_;

    my $empire      = $self->get_empire_by_session($session_id);
    my $building    = $self->get_building($empire, $building_id);
    my $body        = $building->body;
    my $now         = time;
    my $alliance_id = $empire->alliance_id;

    $page_number    ||= 1;
    my @fleet;

    my $fleets = $building->incoming_fleets->search({}, {
        rows        => 25, 
        page        => $page_number, 
        join        => 'body',
        prefetch    => 'body',
        order_by    => 'date_available',
	});

    my $see_fleet_info  = ($building->level * 350) * ( $building->efficiency / 100 );
    my $see_fleet_path  = ($building->level * 450) * ( $building->efficiency / 100 );
    my @my_planets      = $empire->planets->get_column('id')->all;

    # First tick foreign planets (once only irrespective of the number of fleets sent from there)
    my $foreign_body;
    # cache for foreign empires
    my $empires;
    while (my $fleet = $fleets->next) {
        if ($fleet->date_available->epoch <= $now) {
            $foreign_body->{$fleet->body_id} = $fleet;
        }
        $empires->{$fleet->body_id} ||= $fleet->body->empire;
    }
    foreach my $foreign_body_id (keys %$foreign_body) {
        $foreign_body->{$foreign_body_id}->body->tick;
    }


    $fleets->reset;
    FLEET:
    while (my $fleet = $fleets->next) {
        next FLEET if $fleet->date_available->epoch <= $now;

        my $show_fleet_info = 0;
        my $show_fleet_path = 0;
        my %fleet_info = (
            id              => $fleet->id,
            name            => 'Unknown',
            type_human      => 'Unknown',
            type            => 'unknown',
            date_arrives    => $fleet->date_available_formatted,
            quantity        => $fleet->quantity,
            from            => {},
        );
        # show all ship details if the fleet is our own or allied
        if (    $fleet->body_id ~~ \@my_planets
            or  $see_fleet_path >= $fleet->stealth
            or  $alliance_id and $empires->{$fleet->body_id}->alliance_id == $alliance_id
            ) {
            $show_fleet_info = 1;
            $show_fleet_path = 1;
        }
        # show fleet info if the space port is a high enough level
        if ($see_fleet_path >= $fleet->stealth) {
            $show_fleet_path = 1;
        }
        # see the fleet details if the space port is a high enough level
        if ($see_fleet_info >= $fleet->stealth) {
            $show_fleet_info = 1;
        }

        if ($see_fleet_path) {
            $fleet_info{from} = {
                id      => $fleet->body_id,
                name    => $fleet->body->name,
                empire  => {
                    id      => $fleet->body->empire_id,
                    name    => $empires->{$fleet->body_id}->name,
                },
            };
        }
        if ($see_fleet_info) {
            $fleet_info{name} = $fleet->name;
            $fleet_info{type} = $fleet->type;
            $fleet_info{type_human} = $fleet->type_formatted;
        }
        push @fleet, \%fleet_info;
    }
    return {
        status              => $self->format_status($empire, $building->body),
        number_of_fleets    => $fleets->pager->total_entries,
        fleets              => \@fleet,
    };
}


sub view_ships_orbiting {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    $page_number ||= 1;
    my @fleet;
    my $now = time;
    my $ships = $building->orbiting_ships->search({}, {rows=>25, page=>$page_number, join => 'body' });
    my $see_ship_type = ($building->effective_level * 350) * ( $building->effective_efficiency / 100 );
    my $see_ship_path = ($building->effective_level * 450) * ( $building->effective_efficiency / 100 );
    my @my_planets = $empire->planets->get_column('id')->all;
    while (my $ship = $ships->next) {
            if ($ship->date_available->epoch <= $now) {
                $ship->body->tick;
            }
            my %ship_info = (
                    id              => $ship->id,
                    name            => 'Unknown',
                    type_human      => 'Unknown',
                    type            => 'unknown',
                    date_arrived    => $ship->date_available_formatted,
                    from            => {},
                    image           => 'unknown',
                );
            if ($ship->body_id ~~ \@my_planets || $see_ship_path >= $ship->stealth) {
                $ship_info{from} = {
                    id      => $ship->body->id,
                    name    => $ship->body->name,
                    empire  => {
                        id      => $ship->body->empire->id,
                        name    => $ship->body->empire->name,
                    },
                };
                if ($ship->body_id ~~ \@my_planets || $see_ship_type >= $ship->stealth) {
                    $ship_info{name} = $ship->name;
                    $ship_info{type} = $ship->type;
                    $ship_info{type_human} = $ship->type_formatted;
                    $ship_info{image}      = $ship->image;
                }
            }
            push @fleet, \%ship_info;
    }
    return {
        status                      => $self->format_status($session, $building->body),
        number_of_ships             => $ships->pager->total_entries,
        ships                       => \@fleet,
    };
}

sub _view_ships {
    my ($self, $session_id, $building_id, $page_number, $method) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my @fleet;
    my $now = time;
    my $ships = $building->$method->search({}, {rows=>25, page=>$page_number, join => 'body' });
    my $see_ship_type = ($building->effective_level * 350) * ( $building->effective_efficiency / 100 );
    my $see_ship_path = ($building->effective_level * 450) * ( $building->effective_efficiency / 100 );
    my @my_planets = $empire->planets->get_column('id')->all;
    while (my $ship = $ships->next) {
        if ($ship->date_available->epoch <= $now) {
            $ship->body->tick;
        }
        else {
            my %ship_info = (
                    id              => $ship->id,
                    name            => 'Unknown',
                    type_human      => 'Unknown',
                    type            => 'unknown',
                    date_arrives    => $ship->date_available_formatted,
                    from            => {},
                    image           => 'unknown',
                );
            if ($ship->body_id ~~ \@my_planets || $see_ship_path >= $ship->stealth) {
                $ship_info{from} = {
                    id      => $ship->body->id,
                    name    => $ship->body->name,
                    empire  => {
                        id      => $ship->body->empire->id,
                        name    => $ship->body->empire->name,
                    },
                };
                if ($ship->body_id ~~ \@my_planets || $see_ship_type >= $ship->stealth) {
                    $ship_info{name} = $ship->name;
                    $ship_info{type} = $ship->type;
                    $ship_info{type_human} = $ship->type_formatted;
                    $ship_info{image}      = $ship->image;
                }
            }
            push @fleet, \%ship_info;
        }
    }
    return {
        status                      => $self->format_status($session, $building->body),
        number_of_ships             => $ships->pager->total_entries,
        ships                       => \@fleet,
    };
}

sub name_ship {
    my ($self, $session_id, $building_id, $ship_id, $name) = @_;
    Lacuna::Verify->new(content=>\$name, throws=>[1005, 'Invalid name for a ship.'])
        ->not_empty
        ->no_profanity
        ->length_lt(31)
        ->no_restricted_chars;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, "Ship not found."];
    }    
    unless ($ship->body_id eq $building->body_id) {
        confess [1013, "You can't manage a ship that is not yours."];
    }
    $ship->name($name);
    $ship->update;
    return {
        status                      => $self->format_status($session, $building->body),
    };
}

sub scuttle_ship {
    my ($self, $session_id, $building_id, $ship_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, "Ship not found."];
    }    
    unless ($ship->task eq 'Docked') {
        confess [1013, "You can't scuttle a ship that's not docked."];
    }    
    unless ($ship->body_id eq $building->body_id) {
        confess [1013, "You can't manage a ship that is not yours."];
    }
    $ship->delete;
    return {
        status                      => $self->format_status($session, $building->body),
    };    
}

sub mass_scuttle_ship {
    my ($self, $session_id, $building_id, $ship_ids) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;

    if (scalar @{$ship_ids} > 6000) {
        confess [ 1099, "More ships than can be docked on one planet!" ];
    }
    my %shash = map { $_ => 1 } grep { !($_ =~ m/\D/) } @{$ship_ids};
    my @ship_ids = sort keys %shash;
    Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {id      => { in => \@ship_ids },
         task    =>'Docked',
         body_id => $building->body_id,
        }
    )->delete;

    return {
        status                      => $self->format_status($session, $building->body),
    };    
}

sub view_battle_logs {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    $page_number ||= 1;
    my @logs;
    my $battle_logs = $building->battle_logs->search({}, { rows=>25, page=>$page_number, order_by => => { -desc => 'date_stamp' } });
    while (my $log = $battle_logs->next) {
        push @logs, {
            date                => format_date($log->date_stamp),
            attacking_empire_id => $log->attacking_empire_id,
            attacking_empire    => $log->attacking_empire_name,
            attacking_body_id   => $log->attacking_body_id,
            attacking_body      => $log->attacking_body_name,
            attacking_unit      => $log->attacking_unit_name,
            attacking_type      => $log->attacking_type,
            defending_empire_id => $log->defending_empire_id,
            defending_empire    => $log->defending_empire_name,
            defending_body_id   => $log->defending_body_id,
            defending_body      => $log->defending_body_name,
            defending_unit      => $log->defending_unit_name,
            defending_type      => $log->defending_type,
            attacked_empire_id  => $log->attacked_empire_id,
            attacked_empire     => $log->attacked_empire_name,
            attacked_body_id    => $log->attacked_body_id,
            attacked_body       => $log->attacked_body_name,
            victory_to          => $log->victory_to,
        };
    }
    return {
        status          => $self->format_status($session, $building->body),
        number_of_logs  => $battle_logs->pager->total_entries,
        battle_log      => \@logs,
    };
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;

    my $empire      = $self->get_empire_by_session($session_id);
    my $building    = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out         = $orig->($self, $empire, $building);
print STDERR "###### FLEET VIEW [".$building->level."] #######\n";

    return $out unless $building->level > 0;


    my $docked = $building->body->fleets->search({ task => 'Docked' });
    my %ships;
    while (my $fleet = $docked->next) {
        $ships{$fleet->type} += $fleet->quantity;
    }
    $out->{docked_ships} = \%ships;
    $out->{max_ships} = $building->max_ships;
    $out->{docks_available} = $building->docks_available;
    return $out;
};

 
__PACKAGE__->register_rpc_method_names(qw(send_ship_types get_fleet_for get_incoming_for view_incoming_fleets get_fleets_for send_ship send_fleet recall_ship recall_all recall_spies scuttle_ship name_ship prepare_fetch_spies fetch_spies prepare_send_spies send_spies view_ships_orbiting view_fleets_travelling view_all_fleets view_battle_logs));

no Moose;
__PACKAGE__->meta->make_immutable;

