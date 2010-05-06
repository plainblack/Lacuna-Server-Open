package Lacuna::Building::SpacePort;

use Moose;
extends 'Lacuna::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use Lacuna::Util qw(cname format_date);

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
        $star = Lacuna->db->resultset('star')->find($target->{star_id});
    }
    elsif (exists $target->{star_name}) {
        $star = Lacuna->db->resultset('star')->search(
            where   => { name_cname => cname($target->{star_name}) },
        )->next;
    }
    elsif (exists $target->{x}) {
        $star = Lacuna->db->resultset('star')->search(
            where   => { x => $target->{x}, y => $target->{y}, z => $target->{z} },
        )->next;
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
        $target_body = Lacuna->db->resultset('body')->find($target->{body_id});
    }
    elsif (exists $target->{body_name}) {
        $target_body = Lacuna->db->resultset('body')->search(
            where   => { name_cname => cname($target->{body_name}) },
        )->next;
    }
    elsif (exists $target->{x}) {
        $target_body = Lacuna->db->resultset('body')->search(
            where   => { x => $target->{x}, y => $target->{y}, z => $target->{z}, orbit => $target->{orbit} },
        )->next;
    }
    unless (defined $target_body) {
        confess [ 1002, 'Could not find the target body.', $target];
    }
    return $target_body;
}

sub send_probe {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $empire->get_body($body_id);
    my $star = $self->find_star($target);

    # check the observatory probe count
    my $count = Lacuna->db->resultset('probes')->count(where => { body_id => $body->id });
    $count += Lacuna->db->resultset('travel_queue')->count(where => { body_id => $body->id, ship_type=>'probe' });
    my $observatory_level = $body->get_buildings_of_class('Lacuna::DB::Result::Building::Observatory')->next->level;
    if ($count >= $observatory_level * 3) {
        confess [ 1009, 'You are already controlling the maximum amount of probes for your Observatory level.'];
    }
    
    # send the probe
    my $sent = $body->spaceport->send_probe($star);

    return { probe => { date_arrives => format_date($sent->date_arrives)}, status => $empire->get_status };
}

sub send_spy_pod {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $empire->get_body($body_id);
    my $target_body = $self->find_body($target);
    
    # make sure it's a valid target
    if ($target_body->isa('Lacuna::DB::Result::Body::Asteroid')) {
        confess [ 1009, 'Cannot send a spy to an asteroid.'];
    }
    elsif (! defined $target_body->empire) {
        confess [ 1009, 'Cannot send a spy to an unoccupied planet.'];
    }
    elsif ($target_body->isa('Lacuna::DB::Result::Body::Planet') && $target_body->empire->is_isolationist) {
        confess [ 1013, sprintf('%s is an isolationist empire, and must be left alone.',$target_body->empire->name)];
    }
    
    # get a spy
    my $spy;
    my $spies = Lacuna->db->resultset('spies')->search(
        where       => {task => ['in','Idle','Training'], on_body_id=>$body->id, empire_id=>$empire->id},
        consistent  => 1,
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

    return { spy_pod => { date_arrives => format_date($sent->date_arrives), carrying_spy => { id => $spy->id, name => $spy->name }}, status => $empire->get_status };
}

sub send_mining_platform_ship {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $empire->get_body($body_id);
    my $target_body = $self->find_body($target);
    
    # make sure it's a valid target
    unless ($target_body->isa('Lacuna::DB::Result::Body::Asteroid')) {
        confess [ 1009, 'Can only send a mining platform ship to an asteroid.'];
    }
    
    # send the ship
    my $sent = $body->spaceport->send_mining_platform_ship($target_body);

    return { mining_platform_ship => { date_arrives => format_date($sent->date_arrives) }, status => $empire->get_status };
}

sub send_gas_giant_settlement_platform_ship {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $empire->get_body($body_id);
    my $target_body = $self->find_body($target);
    
    # make sure it's a valid target
    unless ($target_body->isa('Lacuna::DB::Result::Body::Planet::GasGiant')) {
        confess [ 1009, 'Can only send a gas giant settlement platform ship to a gas giant.'];
    }
    
    # send the ship
    my $sent = $body->spaceport->send_gas_giant_settlement_platform_ship($target_body);

    return { gas_giant_settlement_platform_ship => { date_arrives => format_date($sent->date_arrives) }, status => $empire->get_status };
}

sub send_terraforming_platform_ship {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $empire->get_body($body_id);
    my $target_body = $self->find_body($target);
    
    # make sure it's a valid target
    unless ($target_body->isa('Lacuna::DB::Result::Body::Planet')) {
        confess [ 1009, 'Can only send a terraforming platfom ship to a planet.'];
    }
    
    # send the ship
    my $sent = $body->spaceport->send_terraforming_platform_ship($target_body);

    return { terraforming_platform_ship => { date_arrives => format_date($sent->date_arrives) }, status => $empire->get_status };
}

sub send_colony_ship {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $empire->get_body($body_id);
    my $target_body = $self->find_body($target);
    
    # make sure it's a valid target
    unless ($target_body->isa('Lacuna::DB::Result::Body::Planet')) {
        confess [ 1009, 'Can only send a colony ship to a planet.'];
    }
    if ($target_body->empire_id ne 'None') {
        confess [ 1013, 'That planet is already inhabited.'];
    }
    
    # make sure you have enough happiness
    if ( $empire->happiness < $empire->next_planet_cost) {
        confess [ 1011, 'You do not have enough happiness to colonize another planet.', [$empire->next_planet_cost]];
    }
        
    # send the ship
    my $sent = $body->spaceport->send_colony_ship($target_body);

    return { colony_ship => { date_arrives => format_date($sent->date_arrives) }, status => $empire->get_status };
}

sub view_ships_travelling {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $page_number ||= 1;
    my $body = $building->body;
    $body->tick;
    my $count = Lacuna->db->resultset('Lacuna::DB::Result::TravelQueue')->count(where=>{body_id=>$body->id});
    my @travelling;
    my $ships = $body->ships_travelling->paginate(25, $page_number);
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
            type    => (ref $target eq 'Lacuna::DB::Result::Star') ? 'star' : 'body',
        };
        if ($ship->direction ne 'outgoing') {
            my $temp = $from;
            $from = $to;
            $to = $temp;
        }
        push @travelling, {
            id              => $ship->id,
            ship_type       => $ship->ship_type,
            to              => $to,
            from            => $from,
            date_arrives    => $ship->date_arrives_formatted,
        };
    }
    return {
        status                      => $empire->get_status,
        number_of_ships_travelling  => $count,
        ships_travelling            => \@travelling,
    };
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $out = $orig->($self, $empire, $building);
    return $out unless $building->level > 0;
    $building->check_for_completed_ships;
    $building->save_changed_ports;
    my %ships;
    foreach my $type (SHIP_TYPES) {
        my $count = $type.'_count';
        $ships{$type} = $building->$count;
    }
    $out->{docked_ships} = \%ships;
    return $out;
};

__PACKAGE__->register_rpc_method_names(qw(send_probe send_spy_pod view_ships_travelling));


no Moose;
__PACKAGE__->meta->make_immutable;

