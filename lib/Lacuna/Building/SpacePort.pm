package Lacuna::Building::SpacePort;

use Moose;
extends 'Lacuna::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use Lacuna::Util qw(cname format_date);

sub app_url {
    return '/spaceport';
}

sub model_class {
    return 'Lacuna::DB::Building::SpacePort';
}

sub spaceports {
    my ($self, $body) = @_;
    return $body->get_buildings_of_class($self->model_class);
}

sub check_for_completed_ships {
    my ($self, $body, $spaceport) = @_;
    my $shipyards = $body->get_buildings_of_class('Lacuna::DB::Building::Shipyard');
    while (my $shipyard = $shipyards->next) {
        $shipyard->check_for_completed_ships($spaceport);
    }
}

sub send_probe {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $empire->get_body($body_id);
    
    # find the star
    my $star;
    if (exists $target->{star_id}) {
        $star = $self->simpledb->domain('star')->find($target->{star_id});
    }
    elsif (exists $target->{star_name}) {
        $star = $self->simpledb->domain('star')->search(
            where   => { name_cname => cname($target->{star_name}) },
        )->next;
    }
    elsif (exists $target->{x}) {
        $star = $self->simpledb->domain('star')->search(
            where   => { x => $target->{x}, y => $target->{y}, z => $target->{z} },
        )->next;
    }
    unless (defined $star) {
        confess [ 1002, 'No such star.', $target];
    }

    # check the observatory probe count
    my $count = $self->simpledb->domain('probes')->count(where => { body_id => $body->id });
    $count += $self->simpledb->domain('travel_queue')->count(where => { body_id => $body->id, ship_type=>'probe' });
    my $observatory_level = $body->get_buildings_of_class('Lacuna::DB::Building::Observatory')->next->level;
    if ($count >= $observatory_level * 3) {
        confess [ 1009, 'You are already controlling the maximum amount of probes for your Observatory level.'];
    }
    
    # finish building any ships in queue
    $self->check_for_completed_ships($body);

    # send the probe
    my $ports = $self->spaceports($body);
    my $sent;
    while (my $port = $ports->next) {
        if ($port->probe_count) {
            $sent = $port->send_probe($star);
            last;
        }
    }
    unless ($sent) {
        confess [ 1002, 'You have no probes to send.'];
    }
    return { probe => { date_arrives => format_date($sent->date_arrives)}, status => $empire->get_status };
}

sub view_ships_travelling {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $page_number ||= 1;
    my $body = $building->body;
    $body->tick;
    my $count = $self->simpledb->domain('Lacuna::DB::TravelQueue')->count(where=>{body_id=>$body->id});
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
            type    => (ref $target eq 'Lacuna::DB::Star') ? 'star' : 'body',
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
    $self->check_for_completed_ships($building->body, $building);
    my %ships;
    foreach my $type (SHIP_TYPES) {
        my $count = $type.'_count';
        $ships{$type} = $building->$count;
    }
    $out->{docked_ships} = \%ships;
    return $out;
};

__PACKAGE__->register_rpc_method_names(qw(send_probe view_ships_travelling));


no Moose;
__PACKAGE__->meta->make_immutable;

