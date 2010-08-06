package Lacuna::RPC::Building::SpacePort;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use Lacuna::Util qw(format_date);

sub app_url {
    return '/spaceport';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::SpacePort';
}

sub find_star {
    my ($self, $target) = @_;
    my $star;
    if (exists $target->{star_id}) {
        $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($target->{star_id});
    }
    elsif (exists $target->{star_name}) {
        $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({ name => $target->{star_name} }, {rows=>1})->single;
    }
    elsif (exists $target->{x}) {
        $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({ x => $target->{x}, y => $target->{y} }, {rows=>1})->single;
    }
    unless (defined $star) {
        confess [ 1002, 'Could not find the target star.', $target];
    }
    return $star;
}

sub find_body {
    my ($self, $target) = @_;
    my $target_body;
    if (exists $target->{body_id}) {
        $target_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target->{body_id});
    }
    elsif (exists $target->{body_name}) {
        $target_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({ name => $target->{body_name} }, {rows=>1})->single;
    }
    elsif (exists $target->{x}) {
        $target_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({ x => $target->{x}, y => $target->{y} }, {rows=>1})->single;
    }
    unless (defined $target_body) {
        confess [ 1002, 'Could not find the target body.', $target];
    }
    return $target_body;
}

sub send_probe {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    my $star = $self->find_star($target);

    # check the observatory probe count
    my $count = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({ body_id => $body->id })->count;
    $count += Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ body_id => $body->id, type=>'probe', task=>'Travelling' })->count;
    my $observatory_level = 0;
    my $observatory = $body->get_buildings_of_class('Lacuna::DB::Result::Building::Observatory')->next;
    if (defined $observatory) {
	$observatory_level = $observatory->level;
    }
    if ($count >= $observatory_level * 3) {
        confess [ 1009, 'You are already controlling the maximum amount of probes for your Observatory level.'];
    }
    
    # send the probe
    my $sent = $body->spaceport->send_probe($star);

    return { probe => { date_arrives => format_date($sent->date_available)}, status => $self->format_status($empire, $body) };
}

sub send_spy_pod {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    my $target_body = $self->find_body($target);
    
    # make sure it's a valid target
    if ($target_body->isa('Lacuna::DB::Result::Map::Body::Asteroid')) {
        confess [ 1009, 'Cannot send a spy to an asteroid.'];
    }
    elsif (! defined $target_body->empire) {
        confess [ 1009, 'Cannot send a spy to an unoccupied planet.'];
    }
    elsif ($target_body->isa('Lacuna::DB::Result::Map::Body::Planet') && $target_body->empire->is_isolationist) {
        confess [ 1013, sprintf('%s is an isolationist empire, and must be left alone.',$target_body->empire->name)];
    }
    
    # get a spy
    my $spy;
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
        {task => ['in','Idle','Training'], on_body_id=>$body->id, empire_id=>$empire->id},
        );
    while (my $possible_spy = $spies->next) {
        if ($possible_spy->is_available) {
            $spy = $possible_spy;
            last;
        }
    }
    unless (defined $spy) {
        confess [ 1002, 'You have no idle spies to send.'];
    }

    # send the pod
    my $sent = $body->spaceport->send_spy_pod($target_body, $spy);

    return { spy_pod => { date_arrives => format_date($sent->date_available), carrying_spy => { id => $spy->id, name => $spy->name }}, status => $self->format_status($empire, $body) };
}

sub send_spies {
    my ($self, $session_id, $body_id, $target, $ship_id, $spy_ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    my $target_body = $self->find_body($target);
    
    # make sure it's a valid target
    if ($target_body->isa('Lacuna::DB::Result::Map::Body::Asteroid')) {
        confess [ 1009, 'Cannot send a spy to an asteroid.'];
    }
    elsif (! defined $target_body->empire) {
        confess [ 1009, 'Cannot send a spy to an unoccupied planet.'];
    }
    elsif ($target_body->isa('Lacuna::DB::Result::Map::Body::Planet') && $target_body->empire->is_isolationist) {
        confess [ 1013, sprintf('%s is an isolationist empire, and must be left alone.',$target_body->empire->name)];
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
    elsif ($ship->hold_size <= (scalar(@{$spy_ids}) * 300)) {
        confess [1010, "The ship cannot hold the spies selected."];
    }
    
    # send it
    $ship->send(
        target      => $target,
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
        ship    => {
            date_arrives    => $ship->date_available_formatted,
            spies_sent      => \@ids_sent,
            spies_not_sent  => \@ids_not_sent,
        },
        status => $self->format_status($empire, $body)
    };
}

sub fetch_spies {
    my ($self, $session_id, $body_id, $target, $ship_id, $spy_ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    my $target_body = $self->find_body($target);

    # get the ship
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, "Ship not found."];
    }
    unless ($ship->is_available) {
        confess [1010, "That ship is not available."];
    }
    
    # check size
    if ($ship->hold_size <= (scalar(@{$spy_ids}) * 300)) {
        confess [1010, "The ship cannot hold the spies selected."];
    }
    
    # send it
    $ship->send(
        target      => $target,
        payload     => { fetch_spies => $spy_ids },
    );

    return {
        ship    => {
            date_arrives    => $ship->date_available_formatted,
        },
        status => $self->format_status($empire, $body)
    };
}

sub get_available_spy_ships {
    my ($self, $session_id, $body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);

    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {type => { in => [qw(spy_pod cargo_ship smuggler_ship)]}, task=>'Docked', body_id => $body_id},
        {order_by => 'name', rows=>25}
    );
    my @out;
    while (my $ship = $ships->next) {
        push @out, {
            name        => $ship->name,
            id          => $ship->id,
            hold_size   => $ship->hold_size,
            speed       => $ship->speed,
            type        => $ship->type,
        };
    }
    return {
        status  => $self->format_status($empire),
        ships   => \@out,
    };
}

sub get_available_spy_ships_for_fetch {
    my ($self, $session_id, $body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);

    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {type => { in => [qw(cargo_ship smuggler_ship)]}, task=>'Docked', body_id => $body_id},
        {order_by => 'name', rows=>25}
    );
    my @out;
    while (my $ship = $ships->next) {
        push @out, {
            name        => $ship->name,
            id          => $ship->id,
            hold_size   => $ship->hold_size,
            speed       => $ship->speed,
            type        => $ship->type,
        };
    }
    return {
        status  => $self->format_status($empire),
        ships   => \@out,
    };
}


sub get_my_available_spies {
    my ($self, $session_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $target_body = $self->find_body($target);

    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
        {on_body_id => $target_body->id, empire_id => $empire->id, task => 'Idle' },
        {order_by => 'name', rows=>25}
    );
    my @out;
    while (my $spy = $spies->next) {
        push @out, {
            name        => $spy->name,
            id          => $spy->id,
            level       => $spy->level,
            from        => {
                name    => $spy->from_body->name,
                id      => $spy->from_body_id,
            },
        };
    }
    return {
        status  => $self->format_status($empire),
        spies   => \@out,
    };
}

sub send_mining_platform_ship {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    my $target_body = $self->find_body($target);
    
    # make sure it's a valid target
    unless ($target_body->isa('Lacuna::DB::Result::Map::Body::Asteroid')) {
        confess [ 1009, 'Can only send a mining platform ship to an asteroid.'];
    }

    # make sure we pass the prereqs
    my $ministry = $body->mining_ministry;
    unless (defined $ministry) {
	confess [ 1010, 'Cannot control platforms without a Mining Ministry.'];
    }
    $ministry->can_add_platform($target_body);
    
    # send the ship
    my $sent = $body->spaceport->send_mining_platform_ship($target_body);

    return { mining_platform_ship => { date_arrives => format_date($sent->date_available) }, status => $self->format_status($empire, $body) };
}

sub send_gas_giant_settlement_platform_ship {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    my $target_body = $self->find_body($target);
    
    # make sure it's a valid target
    unless ($target_body->isa('Lacuna::DB::Result::Map::Body::Planet::GasGiant')) {
        confess [ 1009, 'Can only send a gas giant settlement platform ship to a gas giant.'];
    }
    
    # send the ship
    my $sent = $body->spaceport->send_gas_giant_settlement_platform_ship($target_body);

    return { gas_giant_settlement_platform_ship => { date_arrives => format_date($sent->date_available) }, status => $self->format_status($empire, $body) };
}

sub send_terraforming_platform_ship {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    my $target_body = $self->find_body($target);
    
    # make sure it's a valid target
    unless ($target_body->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        confess [ 1009, 'Can only send a terraforming platfom ship to a planet.'];
    }
    
    # send the ship
    my $sent = $body->spaceport->send_terraforming_platform_ship($target_body);

    return { terraforming_platform_ship => { date_arrives => format_date($sent->date_available) }, status => $self->format_status($empire, $body) };
}

sub send_colony_ship {
    my ($self, $session_id, $body_id, $target) = @_;
    my $target_body = $self->find_body($target);
    
    # make sure it's a valid target
    unless ($target_body->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        confess [ 1009, 'Can only send a colony ship to a planet.'];
    }
    if ($target_body->empire_id) {
        confess [ 1013, 'That planet is already inhabited.'];
    }
    my $empire = $self->get_empire_by_session($session_id);
    my $species = $empire->species;
    unless ($target_body->orbit <= $species->max_orbit && $target_body->orbit >= $species->min_orbit) {
        confess [ 1009, 'Your species cannot survive on that planet.' ];
    }
    
    # make sure you have enough happiness
    my $next_colony_cost = $empire->next_colony_cost;
    my $body = $self->get_body($empire, $body_id);
    unless ( $body->happiness > $next_colony_cost) {
        confess [ 1011, 'You do not have enough happiness to colonize another planet. You need '.$next_colony_cost.' happiness.', [$next_colony_cost]];
    }
        
    # send the ship
    $body->spend_happiness($next_colony_cost)->update;
    my $sent = $body->spaceport->send_colony_ship($target_body, { colony_cost => $next_colony_cost });

    return { colony_ship => { date_arrives => format_date($sent->date_available) }, status => $self->format_status($empire, $body) };
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
        my $target = ($ship->foreign_body_id) ? $ship->foreign_body : $ship->foreign_star;
        my $from = {
            id      => $body->id,
            name    => $body->name,
            type    => 'body',
        };
        my $to = {
            id      => $target->id,
            name    => $target->name,
            type    => (ref $target eq 'Lacuna::DB::Result::Map::Star') ? 'star' : 'body',
        };
        if ($ship->direction ne 'out') {
            my $temp = $from;
            $from = $to;
            $to = $temp;
        }
        push @travelling, {
            id              => $ship->id,
            name            => $ship->name,
            type            => $ship->type,
            to              => $to,
            from            => $from,
            date_arrives    => $ship->date_available_formatted,
        };
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
        push @fleet, {
            id              => $ship->id,
            name            => $ship->name,
            type            => $ship->type,
            task            => $ship->task,
            speed           => $ship->speed,
            hold_size       => $ship->hold_size,
        };
    }
    return {
        status                      => $self->format_status($empire, $body),
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
 
__PACKAGE__->register_rpc_method_names(qw(scuttle_ship name_ship fetch_spies send_spies get_available_spy_ships_for_fetch get_available_spy_ships get_my_available_spies send_probe send_spy_pod send_colony_ship send_mining_platform_ship view_ships_travelling view_all_ships));


no Moose;
__PACKAGE__->meta->make_immutable;

