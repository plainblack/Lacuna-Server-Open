package Lacuna::RPC::Building::SpacePort;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use Lacuna::Util qw(format_date);
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

sub get_ships_for {
    my ($self, $session_id, $body_id, $target_params) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    my $target = $self->find_target($target_params);
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    
    my @incoming;
    my $incoming_rs = $ships->search({
            task => 'Travelling', 
            direction => 'out',
            'body.empire_id' => $empire->id,
    	},
        { join => 'body' }
	);
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
    
    my @unavailable;
    my @available;
    my $available_rs = $ships->search({task => 'Docked', body_id=>$body->id });
    while (my $ship = $available_rs->next) {
        eval{ $ship->can_send_to_target($target) };
        if ($@) {
    	    push @unavailable, { ship => $ship->get_status, reason => $@ };
            next;
        }
        $ship->body($body);
        push @available, $ship->get_status;
    }
    
    my %out = (
        status      => $self->format_status($empire, $body),
        incoming    => \@incoming,
        available   => \@available,
        unavailable => \@unavailable,
    );
    
    if ($target->isa('Lacuna::DB::Result::Map::Body::Asteroid')) {
        my $platforms = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->search({asteroid_id => $target->id});
        while (my $platform = $platforms->next) {
            my $empire = $platform->planet->empire;
            push @{$out{mining_platforms}}, {
                empire_id   => $empire->id,
                empire_name => $empire->name,
            };
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
    unless ($ship->task eq 'Docked') {
        confess [1010, 'That ship is busy.'];
    }
    my $payload;
    my $body = $ship->body;
    $body->empire($empire);
    $ship->can_send_to_target($target);
    given($ship->type) {
        when ('excavator') {
            Lacuna->cache->set('excavator_'.$target->id, $empire->id, 1, 60 * 60 * 24 * 30);
        }
        when ('scow') {
            $body->spend_waste($ship->hold_size)->update;
            $payload = { resources => { waste => $ship->hold_size } };
        }
        when ('colony_ship') {
            confess [ 1009, 'Your species cannot survive on that planet.' ] unless ($target->orbit <= $empire->max_orbit && $target->orbit >= $empire->min_orbit);
            my $next_colony_cost = $empire->next_colony_cost;
            confess [ 1011, 'You do not have enough happiness to colonize another planet. You need '.$next_colony_cost.' happiness.', [$next_colony_cost]] unless ( $ship->body->happiness > $next_colony_cost);
            $body->spend_happiness($next_colony_cost)->update;
            $payload = { colony_cost => $next_colony_cost };
        }
        when ('spy_pod') {
            my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
                {task => ['in','Idle','Training'], on_body_id=>$body->id, empire_id=>$empire->id},
            );
            my $spy;
            while (my $possible_spy = $spies->next) {
                if ($possible_spy->is_available) {
                    $spy = $possible_spy;
                    last;
                }
            }
            confess [ 1002, 'You have no idle spies to send.'] unless (defined $spy);
            $spy->available_on($ship->date_available->clone);
            $spy->on_body_id($target->id);
            $spy->task('Travelling');
            $spy->started_assignment(DateTime->now);
            $spy->update;
            $payload = { spies => [ $spy->id ] };
        }
        when ('spy_shuttle') {
            my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
                {task => ['in','Idle','Training'], on_body_id=>$body->id, empire_id=>$empire->id},
            );
            my @spies;
            while (my $spy = $spies->next) {
                if ($spy->is_available) {
                    $spy->available_on($ship->date_available->clone);
                    $spy->on_body_id($target->id);
                    $spy->task('Travelling');
                    $spy->started_assignment(DateTime->now);
                    $spy->update;
                    push @spies, $spy->id;
                    last if (scalar(@spies) == 4);
                }
            }
            confess [ 1002, 'You have no idle spies to send.'] unless (scalar(@spies));
            $payload = { spies => \@spies };
        }
    }        
    $ship->send(target => $target, payload => $payload);
    return {
        ship    => $ship->get_status,
        status  => $self->format_status($empire),
    }
}


sub prepare_send_spies {
    my ($self, $session_id, $on_body_id, $to_body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $on_body = $self->get_body($empire, $on_body_id);
    my $to_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($to_body_id);
    
    unless ($to_body->empire_id) {
        confess [1009, "Cannot send spies to an uninhabitted body."];
    }
    if ($to_body->empire->is_isolationist) {
        confess [ 1013, sprintf('%s is an isolationist empire, and must be left alone.',$to_body->empire->name)];
    }

    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {type => { in => [qw(spy_pod cargo_ship smuggler_ship dory spy_shuttle freighter)]}, task=>'Docked', body_id => $on_body_id},
        {order_by => 'name', rows=>100}
    );
    my @ships;
    while (my $ship = $ships->next) {
        push @ships, $ship->get_status;
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
    my $on_body = $self->get_body($empire, $on_body_id);
    my $to_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($to_body_id);
    
    # make sure it's a valid target
    unless ($to_body->empire_id) {
        confess [ 1009, 'Cannot send spies to an uninhabited body.'];
    }
    if ($to_body->empire->is_isolationist) {
        confess [ 1013, sprintf('%s is an isolationist empire, and must be left alone.',$to_body->empire->name)];
    }

    # get the ship
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, "Ship not found."];
    }
    unless ($ship->is_available) {
        confess [1010, "That ship is not available."];
    }

    # check size
    if ($ship->type eq 'spy_pod' && scalar(@{$spy_ids}) == 1) {
        # we're ok
    }
    if ($ship->type eq 'spy_shuttle' && scalar(@{$spy_ids}) <= 4) {
        # we're ok
    }
    elsif ($ship->hold_size <= (scalar(@{$spy_ids}) * 350)) {
        confess [1010, "The ship cannot hold the spies selected."];
    }
    
    # send it
    $ship->send(
        target      => $to_body,
    );

    # get a spies
    my @ids_sent;
    my @ids_not_sent;
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies');
    foreach my $id (@{$spy_ids}) {
        my $spy = $spies->find($id);
        if ($spy->is_available) {
            if ($spy->empire_id == $empire->id) {
                push @ids_sent, $spy->id;
                $spy->task('Travelling');
                $spy->started_assignment(DateTime->now);
                $spy->available_on($ship->date_available);
                $spy->update;
            }
            else {
                push @ids_not_sent, $spy->id;
            }
        }
        else {
            push @ids_not_sent, $spy->id;
        }
    }
    $ship->payload({spies => \@ids_sent });
    $ship->update;

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
    my $to_body = $self->get_body($empire, $to_body_id);
    my $on_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($on_body_id);
    
    unless ($on_body->empire_id) {
        confess [1013, "Cannot fetch spies from an uninhabitted planet."];
    }

    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {type => { '>=' => 350 }, task=>'Docked', body_id => $to_body_id},
        {order_by => 'name', rows=>100}
    );
    my @ships;
    while (my $ship = $ships->next) {
        push @ships, $ship->get_status;
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

sub fetch_spies {
    my ($self, $session_id, $on_body_id, $to_body_id, $ship_id, $spy_ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $to_body = $self->get_body($empire, $to_body_id);
    my $on_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($on_body_id);

    # get the ship
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, "Ship not found."];
    }
    unless ($ship->is_available) {
        confess [1010, "That ship is not available."];
    }

    unless ($on_body->empire_id) {
        confess [1013, "Cannot fetch spies from an uninhabitted planet."];
    }

    if (scalar(@{$spy_ids})) {
        confess [1013, "You can't send a ship to collect no spies."];
    }
    
    # check size
    if ($ship->hold_size <= (scalar(@{$spy_ids}) * 350)) {
        confess [1013, "The ship cannot hold the spies selected."];
    }
    
    # send it
    $ship->send(
        target      => $on_body,
        payload     => { fetch_spies => $spy_ids },
    );

    return {
        ship    => $ship->get_status,
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

sub view_all_ships {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my $body = $building->body;
    my @fleet;
    my $ships = $building->ships->search({}, {rows=>25, page=>$page_number});
    while (my $ship = $ships->next) {
        $ship->body($body);
        push @fleet, $ship->get_status;
    }
    return {
        status                      => $self->format_status($empire, $body),
        number_of_ships             => $ships->pager->total_entries,
        ships                       => \@fleet,
    };    
}

sub view_foreign_ships {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my @fleet;
    my $now = DateTime->now;
    my $ships = $building->foreign_ships->search({}, {rows=>25, page=>$page_number, join => 'body' });
    while (my $ship = $ships->next) {
        if ($ship->date_available <= $now) {
            $ship->body->tick;
        }
        else {
            if ($building->level * 300 >= $ship->stealth) {
                my $from = {};
                if ($building->level * 100 >= $ship->stealth) {
                    $from = {
                        id      => $ship->body->id,
                        name    => $ship->body->name,
                        empire  => {
                            id      => $ship->body->empire->id,
                            name    => $ship->body->empire->name,
                        },
                    };
                }
                push @fleet, {
                    id              => $ship->id,
                    name            => $ship->name,
                    type_human      => $ship->type_formatted,
                    type            => $ship->type,
                    date_arrives    => $ship->date_available_formatted,
                    from            => $from,
                };
            }
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
 
__PACKAGE__->register_rpc_method_names(qw(view_foreign_ships get_ships_for send_ship scuttle_ship name_ship prepare_fetch_spies fetch_spies prepare_send_spies send_spies view_ships_travelling view_all_ships));


no Moose;
__PACKAGE__->meta->make_immutable;

