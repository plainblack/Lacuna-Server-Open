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
        $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({ name => $target_params->{star_name} }, {rows=>1})->single;
    }
    if (exists $target_params->{body_id}) {
        $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target_params->{body_id});
    }
    elsif (exists $target_params->{body_name}) {
        $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({ name => $target_params->{body_name} }, {rows=>1})->single;
    }
    elsif (exists $target_params->{x}) {
        $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({ x => $target_params->{x}, y => $target_params->{y} }, {rows=>1})->single;
        unless (defined $target) {
            $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({ x => $target_params->{x}, y => $target_params->{y} }, {rows=>1})->single;
        }
    }
    unless (defined $target) {
        confess [ 1002, 'Could not find the target.', $target];    
    }
    return $target;
}

sub get_fleet_for {
    my ($self, $session_id, $body_id, $target_params) = @_;

    my $empire  = $self->get_empire_by_session($session_id);
    my $body    = $self->get_body($empire, $body_id);
    my $target  = $self->find_target($target_params);

    my $berth   = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search( {
        class       => 'Lacuna::DB::Result::Building::SpacePort',
        body_id     => $body_id,
        efficiency  => 100,
    } )->get_column('level')->max;
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {
            body_id => $body->id, 
            task => 'docked',
        },{
            '+select'   => [{count => 'id'}],
            '+as'       => [ qw(quantity) ],
            group_by    => [ qw(type speed stealth combat hold_size) ],
        },
    );
    my $summary;
    while (my $ship_group = $ships->next) {
        my $travel_time = Lacuna::DB::Result::Ships->travel_time($body,$target,$ship_group->speed);
        my $type_human  = Lacuna::DB::Result::Ships->type_human($ship_group->type);
        my $summation = {
            type        => $ship_group->type,
            type_human  => $type_human,
            speed       => int($ship_group->speed),
            stealth     => int($ship_group->stealth),
            combat      => int($ship_group->combat),
            quantity    => $ship_group->get_column('quantity'),
            estimated_travel_time => $travel_time,
        };
        push @$summary, $summation;
    }
    my %out = (
        status  => $self->format_status($empire, $body),
        ships   => $summary,
    );
    return \%out;
}

sub get_ships_for {
    my ($self, $session_id, $body_id, $target_params) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    my $target = $self->find_target($target_params);
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    
    my @incoming;
    my $incoming_rs = $ships->search({
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
    my $available_rs = $ships->search( {task => 'Docked',
                                        body_id=>$body->id });
    while (my $ship = $available_rs->next) {
      $ship->body($body);
      eval{ $ship->can_send_to_target($target) };
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
    
    my $max_ships = Lacuna->config->get('ships_per_fleet') || 20;

    my %out = (
        status              => $self->format_status($empire, $body),
        incoming            => \@incoming,
        available           => \@available,
        unavailable         => \@unavailable,
        fleet_send_limit    => $max_ships,
    );
    
  unless ($target->isa('Lacuna::DB::Result::Map::Star')) {
    my @orbiting;
    my $orbiting_rs = $ships->search({task => [qw(Defend Orbiting)], body_id => $body->id, foreign_body_id => $target->id });
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
    my $empire = $self->get_empire_by_session($session_id);
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
    $ship->send(target => $target);
    return {
        ship    => $ship->get_status,
        status  => $self->format_status($empire),
    }
}

sub find_arrival {
    my ($self, $arrival_params) = @_;

    my $now     = DateTime->now;
    my $year    = $now->year,
    my $month   = $now->month;
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
    if ($day < $now->day) {
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

    my $empire  = $self->get_empire_by_session($session_id);
    my $body    = $self->get_body($empire, $body_id);
    my $target  = $self->find_target($target_params);
    my $arrival = $self->find_arrival($arrival_params);

    # calculate the total ships before the expense of any database operations.
    my $total_ships = 0;
    map {$total_ships += $_->{quantity}} @$type_params;
    my $max_ships = Lacuna->config->get('ships_per_fleet') || 20;
    if ($total_ships > $max_ships) {
        confess [1009, 'Too many ships for a fleet.'];
    }

    my $ship_ref;
    my $do_captcha_check = 0;
    foreach my $type_param (@$type_params) {
        foreach my $arg (qw(speed stealth combat quantity)) {
            confess [1002, "$arg cannot be negative."] if $type_param->{$arg} < 0;
            confess [1002, "$arg must be an integer."] if $type_param->{$arg} != int($type_param->{$arg});
        }
        my $type        = $type_param->{type};
        my $speed       = $type_param->{speed};
        my $stealth     = $type_param->{stealth};
        my $combat      = $type_param->{combat};
        my $quantity    = $type_param->{quantity};
        confess [1009, "Cannot send more than one excavator"] if ($type eq 'excavator' and $quantity > 1);

        # TODO Must check for valid berth levels
        # 
        my $ships_rs    = Lacuna->db->resultset('Ships')->search({
            body_id => $body->id,
            task    => 'Docked',
            type    => $type,
            speed   => $speed,
            stealth => $stealth,
            combat  => $combat,
        });
        if ($ships_rs->count < $quantity) {
            confess [1009, "Cannot find $quantity of $type ships."];
        }
        my @ships = $ships_rs->search(undef,{rows => $quantity});
        my $ship = $ships[0];
        # We only need to check one of the ships
        $ship->can_send_to_target($target);
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
    foreach my $ship (values %$ship_ref) {
        $ship->fleet_speed(1);
        $ship->send(target => $target, arrival => $arrival);
    }
    return $self->get_fleet_for($session_id, $body_id, $target_params);
}

sub send_fleet {
  my ($self, $session_id, $ship_ids, $target_params, $set_speed) = @_;
  $set_speed //= 0;
  my $empire = $self->get_empire_by_session($session_id);
  my $target = $self->find_target($target_params);
  my $max_ships = Lacuna->config->get('ships_per_fleet') || 20;
  if (@$ship_ids > $max_ships) {
    confess [1009, 'Too many ships for a fleet.'];
  }
  my @fleet;
  my $speed = 999999999;
  my $excavator = 0;
  for my $ship_id (@$ship_ids) {
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
      confess [1002, 'Could not locate that ship.'];
    }
    unless ($ship->body->empire_id == $empire->id) {
      confess [1010, 'You do not own that ship.'];
    }
    if ($ship->type eq 'excavator') {
      $excavator++;
    }
    $speed = $ship->speed if ( $speed > $ship->speed );
    push @fleet, $ship_id;
  }
  unless ($excavator <= 1) {
    confess [1010, 'Only one Excavator may be sent to a body by this empire.'];
  }
  unless ($set_speed <= $speed) {
    confess [1009, 'Set speed cannot exceed the speed of the slowest ship.'];
  }
  unless ($set_speed >= 0) {
    confess [1009, 'Set speed cannot be less than zero.'];
  }
  $speed = $set_speed if ($set_speed > 0 && $set_speed < $speed);
  my @ret;
  my $captcha_check = 1;
  for my $ship_id (@fleet) {
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    my $body = $ship->body;
    $body->empire($empire);
    $ship->can_send_to_target($target);
    if ($captcha_check && $ship->hostile_action ) {
      $empire->current_session->check_captcha;
      $captcha_check = 0;
    }
    $ship->fleet_speed($speed);
    $ship->send(target => $target);
    push @ret, {
      ship    => $ship->get_status,
    }
  }
  return {
    fleet  => \@ret,
    status  => $self->format_status($empire),
  };
}

sub recall_ship {
  my ($self, $session_id, $building_id, $ship_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
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

    my $target = $self->find_target({body_id => $ship->foreign_body_id});
    $ship->send(
    target    => $target,
    direction  => 'in',
  );
    $ship->body->update;
    return {
        ship    => $ship->get_status,
        status  => $self->format_status($empire),
    }
}

sub recall_all {
  my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
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
        status  => $self->format_status($empire),
    }
}

sub prepare_send_spies {
    my ($self, $session_id, $on_body_id, $to_body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($on_body_id == $to_body_id) {
        confess [1013, "Cannot send spies to one self."];
    }
    my $on_body = $self->get_body($empire, $on_body_id);
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

    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
        {on_body_id => $on_body->id, empire_id => $empire->id },
        {order_by => 'name', rows=>100}
    );
    my @spies;
    while (my $spy = $spies->next) {
        $spy->on_body($on_body);
        if ($spy->is_available) {
            push @spies, $spy->get_status;
        }
    }

    return {
        status  => $self->format_status($empire),
        ships   => \@ships,
        spies   => \@spies,
    };
}

sub send_spies {
    my ($self, $session_id, $on_body_id, $to_body_id, $ship_id, $spy_ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($on_body_id == $to_body_id) {
        confess [1013, "Cannot send spies to one self."];
    }
    my $on_body = $self->get_body($empire, $on_body_id);
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
        status          => $self->format_status($empire, $on_body)
    };
}

sub prepare_fetch_spies {
    my ($self, $session_id, $on_body_id, $to_body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($on_body_id == $to_body_id) {
        confess [1013, "Cannot fetch spies to one self."];
    }
    my $to_body = $self->get_body($empire, $to_body_id);
    my $on_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($on_body_id);
    unless ($on_body->empire_id) {
        confess [1013, "Cannot fetch spies from an uninhabited planet."];
    }

    my $max_berth = $to_body->max_berth;
    unless ($max_berth) {
        $max_berth = 1;
    }

    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {type => { in => [qw(spy_pod cargo_ship smuggler_ship dory spy_shuttle barge)]},
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
        {order_by => 'name', rows=>100}
    );
    my @spies;
    while (my $spy = $spies->next) {
        $spy->on_body($on_body);
        if ($spy->is_available) {
            push @spies, $spy->get_status;
        }
    }
    
    return {
        status  => $self->format_status($empire),
        ships   => \@ships,
        spies   => \@spies,
    };
}

sub fetch_spies {
    my ($self, $session_id, $on_body_id, $to_body_id, $ship_id, $spy_ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($on_body_id == $to_body_id) {
        confess [1013, "Cannot fetch spies to one self."];
    }
    my $to_body = $self->get_body($empire, $to_body_id);
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
        status  => $self->format_status($empire, $to_body),
    };
}



sub view_ships_travelling {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my $body = $building->body;
    my @travelling;
    my $ships = $body->ships_travelling->search(undef, {rows=>25, page=>$page_number});
    while (my $ship = $ships->next) {
        $ship->body($body);
        push @travelling, $ship->get_status;
    }
    return {
        status                      => $self->format_status($empire, $body),
        number_of_ships_travelling  => $ships->pager->total_entries,
        ships_travelling            => \@travelling,
    };
}

sub _ship_paging_options {
    my ($self, $paging) = @_;
    for my $key ( keys %{ $paging } ) {
        # Throw away bad keys
        unless ($key ~~ [qw(page_number items_per_page no_paging)]) {
            delete $paging->{$key};
            next;
        }
    }
    if ($paging->{no_paging}) {
        $paging = {};
    }
    else {
        $paging->{page_number} ||= 1;
        $paging->{items_per_page} ||= 25;
    }
    return $paging;
}

sub _ship_filter_options {
    my ($self, $filter) = @_;

    # Valid filter options include...
    my $options = {
        task    => [qw(Docked Building Mining Travelling Defend Orbiting)],
        tag     => [qw(Trade Colonization Intelligence Exploration War Mining)],
        type    => [SHIP_TYPES],
    };

    # Pull in the list of ship types by tag
    my %tag;
    for my $type ( SHIP_TYPES ) {
        my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({ type => $type });
        for my $tag ( @{$ship->build_tags} ) {
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

sub _ship_sort_options {
    my ($self, $sort) = @_;

    # return the default if it's not one of the following or is 'name'
    if ( ! $sort || $sort eq 'name' || ! $sort ~~ [qw(combat speed stealth task type)] ) {
        return [ 'name' ];
    }

    # append name to the sort options
    return [ $sort, 'name' ];
}

sub view_all_ships {
    my ($self, $session_id, $building_id, $paging, $filter, $sort) = @_;

    $paging = $self->_ship_paging_options( (defined $paging && ref $paging eq 'HASH') ? $paging : {} );
    $filter = $self->_ship_filter_options( (defined $filter && ref $filter eq 'HASH') ? $filter : {} );
    $sort = $self->_ship_sort_options( $sort // 'type' );

    my $attrs = {
        sort_by => $sort
    };
    $attrs->{rows} = $paging->{items_per_page} if ( defined $paging->{items_per_page} );
    $attrs->{page} = $paging->{page_number} if ( defined $paging->{page_number} );

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;
    my @fleet;
    my $ships = $building->ships->search( $filter, $attrs );
    while (my $ship = $ships->next) {
        $ship->body($body);
        push @fleet, $ship->get_status;
    }

    return {
        status                      => $self->format_status($empire, $body),
        number_of_ships             => defined $paging->{page_number} ? $ships->pager->total_entries : $ships->count,
        ships                       => \@fleet,
    };
}

sub view_foreign_ships {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my @fleet;
    my $now = time;
    my $ships = $building->foreign_ships->search({}, {rows=>25, page=>$page_number, join => 'body' });
    my $see_ship_type = ($building->level * 350) * ( $building->efficiency / 100 );
    my $see_ship_path = ($building->level * 450) * ( $building->efficiency / 100 );
    my @my_planets = $empire->planets->get_column('id')->all;
    while (my $ship = $ships->next) {
        if ($ship->date_available->epoch <= $now) {
            # it might be more efficient to move this out of the loop and just remember those bodies
            # that need to be ticked. Rather than ticking the same body (potentially) many times
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
                }
            }
            push @fleet, \%ship_info;
        }
    }
    return {
        status                      => $self->format_status($empire, $building->body),
        number_of_ships             => $ships->pager->total_entries,
        ships                       => \@fleet,
    };
}

sub view_ships_orbiting {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my @fleet;
    my $now = time;
    my $ships = $building->orbiting_ships->search({}, {rows=>25, page=>$page_number, join => 'body' });
    my $see_ship_type = ($building->level * 350) * ( $building->efficiency / 100 );
    my $see_ship_path = ($building->level * 450) * ( $building->efficiency / 100 );
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
                }
            }
            push @fleet, \%ship_info;
    }
    return {
        status                      => $self->format_status($empire, $building->body),
        number_of_ships             => $ships->pager->total_entries,
        ships                       => \@fleet,
    };
}

sub _view_ships {
    my ($self, $session_id, $building_id, $page_number, $method) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @fleet;
    my $now = time;
    my $ships = $building->$method->search({}, {rows=>25, page=>$page_number, join => 'body' });
    my $see_ship_type = ($building->level * 350) * ( $building->efficiency / 100 );
    my $see_ship_path = ($building->level * 450) * ( $building->efficiency / 100 );
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
                }
            }
warn Dumper(\%ship_info); use Data::Dumper;
            push @fleet, \%ship_info;
        }
    }
    return {
        status                      => $self->format_status($empire, $building->body),
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
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
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
        status                      => $self->format_status($empire, $building->body),
    };    
}

sub scuttle_ship {
    my ($self, $session_id, $building_id, $ship_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
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
        status                      => $self->format_status($empire, $building->body),
    };    
}

sub mass_scuttle_ship {
    my ($self, $session_id, $building_id, $ship_ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

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
        status                      => $self->format_status($empire, $building->body),
    };    
}

sub view_battle_logs {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
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
        status          => $self->format_status($empire, $building->body),
        number_of_logs  => $battle_logs->pager->total_entries,
        battle_log      => \@logs,
    };
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
    return $out unless $building->level > 0;
    my $docked = $building->ships->search({ task => 'Docked' });
    my %ships;
    while (my $ship = $docked->next) {
        $ships{$ship->type}++;
    }
    $out->{docked_ships} = \%ships;
    $out->{max_ships} = $building->max_ships;
    $out->{docks_available} = $building->docks_available;
    return $out;
};
 
__PACKAGE__->register_rpc_method_names(qw(send_ship_types get_fleet_for view_foreign_ships get_ships_for send_ship send_fleet recall_ship recall_all recall_spies scuttle_ship name_ship prepare_fetch_spies fetch_spies prepare_send_spies send_spies view_ships_orbiting view_ships_travelling view_all_ships view_battle_logs mass_scuttle_ship));

no Moose;
__PACKAGE__->meta->make_immutable;

