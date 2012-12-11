package Lacuna::RPC::Building::SpacePort;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use Lacuna::Util qw(format_date);
use Data::Dumper;
use POSIX qw(ceil);

use feature "switch";

with 'Lacuna::Role::Navigation';

sub app_url {
    return '/spaceport';
}


sub model_class {
    return 'Lacuna::DB::Result::Building::SpacePort';
}

# Get fleets not available to send to a target
sub view_unavailable_fleets {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            body_id         => shift,
            target          => shift,
            filter          => shift,
            sort            => shift,
        };
    }
    return $self->_view_available_fleets($args, 'unavailable');
}


# Get fleets available to send to a target
sub view_available_fleets {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            body_id         => shift,
            target          => shift,
            filter          => shift,
            sort            => shift,
        };
    }
    return $self->_view_available_fleets($args, 'available');
}

# Routine to go through all docked ships and determine if they are
# 'available' or 'unavailable' to be sent to a target.
#
sub _view_available_fleets {
    my ($self, $args, $option) = @_;

    my $empire  = $self->get_empire_by_session($args->{session_id});
    my $body    = $self->get_body($empire, $args->{body_id});
    my $target  = $self->find_target($args->{target});

    my $filter  = $self->_fleet_filter_options( (defined $args->{filter} && ref $args->{filter} eq 'HASH') ? $args->{filter} : {} );
    my $sort    = $self->_fleet_sort_options( $args->{sort} // 'type' );

    my $attrs = {
        order_by    => $sort,
    };

    my $fleet_rs = Lacuna->db->resultset('Fleet')->search($filter, $attrs);
    $fleet_rs = $fleet_rs->search({
        task        => 'Docked',
        body_id     => $body->id,
    });
    my @available;
    my @unavailable;
    while (my $fleet = $fleet_rs->next) {
        $fleet->body($body);
        my $status = $fleet->get_status;
        eval{ $fleet->can_send_to_target($target) };
        my $reason = $@;
        if ($reason) {
            $status->{reason} = $reason;
            push @unavailable, $status;
        }
        else {
            push @available, $status;
            my $earliest_arrival = $fleet->earliest_arrival($target);
            $status->{earliest_arrival} = {
                month       => sprintf("%02d", $earliest_arrival->month),
                day         => sprintf("%02d", $earliest_arrival->day),
                hour        => sprintf("%02d", $earliest_arrival->hour),
                minute      => sprintf("%02d", $earliest_arrival->minute),
                second      => sprintf("%02d", $earliest_arrival->second),
            };
        }
    }
        
    my %out = (
        status      => $self->format_status($empire),
        $option     => $option eq 'available' ? \@available : \@unavailable,
    );

    return \%out;
}


sub send_fleet {
    my $self = shift;
    my $args = shift;
        
    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            fleet_id    => shift,
            quantity    => shift,
            target      => shift,
            arrival_date=> shift,
        };
    }
    $args->{arrival_date} = {soonest => 1} if not defined $args->{arrival_date};
    
    my $empire  = $self->get_empire_by_session($args->{session_id});
    my $target  = $self->find_target($args->{target});
    my $qty     = $args->{quantity};
    my $fleet   = Lacuna->db->resultset('Fleet')->find({id => $args->{fleet_id}},{prefetch => 'body'});
    if (! defined $fleet) {
        confess [1002, 'Could not locate that fleet.'];
    }
    if ($fleet->body->empire->id != $empire->id) {
        confess [1010, 'You do not own that ship.'];
    }
    if (not defined $qty or $qty < 0 or int($qty) != $qty) {
        confess [1009, 'Quantity must be a positive integer'];
    }
    if ($qty > $fleet->quantity) {
        confess [1009, "You don't have that many ships in the fleet"];
    }
    if ($fleet->type eq 'excavator' and $qty > 1) {
        confess [1009, 'You can only send one excavator to a body'];
    }
    $fleet->can_send_to_target($target);
    if ($fleet->hostile_action) {
        $empire->current_session->check_captcha;
    }
    my $new_fleet = $fleet->split($qty); 

    if ($args->{arrival_date}{soonest}) {
        $new_fleet->send(target => $target);
    }
    else {
        my $arrival_date = $self->calculate_arrival($fleet, $target, $args->{arrival_date});
        $new_fleet->send(target => $target, arrival => $arrival_date);
    }
    return {
        fleet   => $new_fleet->get_status,
        status  => $self->format_status($empire),
    };
}


# calculate arrival time
#
sub calculate_arrival {
    my ($self, $fleet, $target, $args) = @_;

    my $month   = $args->{month};
    my $date    = $args->{date};
    my $hour    = $args->{hour};
    my $minute  = $args->{minute};
    my $second  = $args->{second};
    if ($second != 0 and $second != 15 and $second != 30 and $second != 45) {
        confess [1009, 'Seconds can only be one of 0,15,30 or 45'];
    }
    if ($minute < 0 or $minute > 59 or $minute != int($minute)) {
        confess [1009, 'Minutes must be an integer between 0 and 59'];
    }
    if ($hour < 0 or $hour > 23 or $hour != int($hour)) {
        confess [1009, 'Hours must be an integer between 0 and 23'];
    }
    if ($month < 1 or $month > 12 or $month != int($month)) {
        confess [1009, 'Month must be an integer between 1 and 12'];
    }
    my $now = DateTime->now;
    my $month_now   = $now->month;
    my $year_now    = $now->year;
    my $year        = $year_now;
    # if it is for a date next year
    if ($month < $month_now) {
        $year = $year_now + 1;
    }
    my $arrival_date = DateTime->new(
        year        => $year,
        month       => $month,
        day         => $date,
        hour        => $hour,
        minute      => $minute,
        second      => $second,
    );
    my $earliest_arrival = DateTime->now->add(seconds => $fleet->calculate_travel_time($target));
    if ($arrival_date < $earliest_arrival) {
        confess [1009, 'The fleet is not fast enough to arrive by that date'];
    }
    return $arrival_date;
}

sub recall_fleet {
    my $self = shift;
    my $args = shift;
        
    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            fleet_id    => shift,
            quantity    => shift,
        };
    }
    my $empire  = $self->get_empire_by_session($args->{session_id});
    my $qty     = $args->{quantity};
    my $fleet   = Lacuna->db->resultset('Fleet')->find({id => $args->{fleet_id}},{prefetch => 'body'});
    if (! defined $fleet) {
        confess [1002, 'Could not locate that fleet.'];
    }
    if ($fleet->body->empire->id != $empire->id) {
        confess [1010, 'You do not own that fleet.'];
    }
    $fleet->has_that_quantity($qty);
    $fleet->can_recall;

    my $target = $self->find_target({body_id => $fleet->foreign_body_id});

    my $new_fleet = $fleet->split($qty);
    $new_fleet->recall;
    my $body = $new_fleet->body;
    #$body->update;
    # to satisfy 'view' get a Space Port
    $args->{building_id} = $body->spaceport->id;
    return $self->view($args);
}

sub prepare_send_spies {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            on_body_id  => shift,
            to_body_id  => shift,
        };
    }
    my $empire  = $self->get_empire_by_session($args->{session_id});
    if ($args->{to_body_id}) {
        $args->{to_body} = { body_id => $args->{to_body_id}};
    }
    my $on_body = $self->get_body($empire, $args->{on_body_id});
    my $to_body = $self->find_target($args->{to_body});
    if (not $to_body->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        confess [1009, "Can only send spies to a planet."];
    }
    if (not $to_body->empire_id) {
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

    my $fleets_rs = Lacuna->db->resultset('Fleet')->search({
        type        => { in => [qw(spy_pod cargo_ship smuggler_ship dory spy_shuttle barge)]},
        task        => 'Docked', 
        body_id     => $on_body->id,
        berth_level => {'<=' => $max_berth },
        },{
        order_by    => 'name', 
        rows        => 100,
    });
    my @fleets;
    while (my $fleet = $fleets_rs->next) {
        push @fleets, $fleet->get_status($to_body);
    }
    # TODO factor out the 'available spies' code
    my $spies = Lacuna->db->resultset('Spies')->search({
        on_body_id  => $on_body->id, 
        empire_id   => $empire->id,
        },{
        order_by    => 'name', 
        rows        => 100,
    });
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
        status  => $self->format_status($empire),
        fleets  => \@fleets,
        spies   => \@spies,
    };
}

sub send_spies {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            on_body_id  => shift,
            to_body_id  => shift,
            fleet_id    => shift,
            spy_ids     => shift,
        };
    }
    $args->{arrival_date} = {soonest => 1} if not defined $args->{arrival_date};
 
    my $empire  = $self->get_empire_by_session($args->{session_id});
    if ($args->{to_body_id}) {
        $args->{to_body} = { body_id => $args->{to_body_id}};
    }
    my $on_body = $self->get_body($empire, $args->{on_body_id});
    my $to_body = $self->find_target($args->{to_body});
    if (not $to_body->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        confess [1009, "Can only send spies to a planet."];
    }
    if (not $to_body->empire_id) {
        confess [1009, "Cannot send spies to an uninhabited body."];
    }
    if ($to_body->empire->is_isolationist) {
        confess [ 1013, sprintf('%s is an isolationist empire, and must be left alone.',$to_body->empire->name)];
    }

    if ($on_body->empire_id != $to_body->empire_id) {
        $empire->current_session->check_captcha;
    }

    # get the fleet
    my $fleet = Lacuna->db->resultset('Fleet')->find($args->{fleet_id});
    if (not defined $fleet) {
        confess [1002, "Fleet not found."];
    }
    if (not $fleet->is_available) {
        confess [1010, "That fleet is not available."];
    }
    my $max_berth = $on_body->max_berth;
    if ($fleet->berth_level > $max_berth) {
        confess [1010, "Your spaceport level is not high enough to support a fleet with a Berth Level of ".$fleet->berth_level."."];
    }

    # check size
    my $spies_to_send = scalar(@{$args->{spy_ids}});

    if ($spies_to_send < 1) {
        confess [1013, "You can't send a fleet with no spies."];
    }
   
    # get the spies
    my @ids_sent;
    my @ids_not_sent;
    my $spies = Lacuna->db->resultset('Spies');
    my $arrives;
    
    if ($args->{arrival_date}{soonest}) {
        $arrives = DateTime->now->add(seconds => $fleet->calculate_travel_time($to_body));
    }
    else {
        $arrives = $self->calculate_arrival($fleet, $to_body, $args->{arrival_date});
    }

    foreach my $id (@{$args->{spy_ids}}) {
        my $spy = $spies->find($id);
        if ($spy->is_available and $spy->on_body_id == $on_body->id) {
            if ($spy->empire_id == $empire->id) {
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
    my $qty = ceil(scalar(@ids_sent) / $fleet->max_occupants);
    if ($fleet->quantity < $qty) {
        confess [1010, "That fleet is not big enough to hold the spies selected."];
    }
    if (scalar @ids_sent) {
        # send it
        $fleet = $fleet->split($qty);
        $fleet->send(
            target      => $to_body,
            payload     => {spies => \@ids_sent }, # add the spies to the payload when we send, otherwise they'll get added again
        );
    }
    return {
        fleet           => $fleet->get_status,
        spies_sent      => \@ids_sent,
        spies_not_sent  => \@ids_not_sent,
        status          => $self->format_status($session, $on_body)
    };
}

sub prepare_fetch_spies {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            on_body_id  => shift,
            to_body_id  => shift,
        };
    }
    my $empire  = $self->get_empire_by_session($args->{session_id});
    if ($args->{on_body_id}) {
        $args->{on_body} = { body_id => $args->{on_body_id}};
    }
    my $to_body = $self->get_body($empire, $args->{to_body_id});
    my $on_body = $self->find_target($args->{on_body});
    if (not $on_body->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        confess [1009, "Can only fetch spies from a planet."];
    }
    if (not $on_body->empire_id) {
        confess [1013, "Cannot fetch spies from an uninhabited body."];
    }

    my $max_berth = $to_body->max_berth || 1;

    my $fleets_rs = Lacuna->db->resultset('Fleet')->search({
        type        => { in => [qw(spy_pod cargo_ship smuggler_ship dory spy_shuttle barge)]},
        task        => 'Docked', 
        body_id     => $to_body->id,
        berth_level => {'<=' => $max_berth },
        },{
        order_by    => 'name', 
        rows        => 100,
    });
    my @fleets;
    while (my $fleet = $fleets_rs->next) {
        push @fleets, $fleet->get_status($on_body);
    }

    # Get all available spies (is this common enough to code in Spies?)
    my $spies_rs = Lacuna->db->resultset('Spies')->search({
        on_body_id  => $on_body->id, 
        empire_id   => $empire->id,
        -or => [
            task        => { in => [ 'Idle', 'Counter Espionage' ], },
            -and        => [
                task            => { in => [ 'Unconscious', 'Debriefing' ], },
                available_on    => { '<' => '\NOW()' }, 
            ],
        ],
        },{
            order_by    => 'name', 
            rows        => 100,
        }
    );

    my @spies;
    while (my $spy = $spies_rs->next) {
        $spy->on_body($on_body);
        if ($spy->is_available) {
            push @spies, $spy->get_status;
        }
        last if (scalar @spies >= 100);
    }
    undef $spies;
    
    return {
        status  => $self->format_status($empire),
        fleets  => \@fleets,
        spies   => \@spies,
    };
}

sub fetch_spies {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            on_body_id  => shift,
            to_body_id  => shift,
            fleet_id    => shift,
            spy_ids     => shift,
        };
    }
    my $empire  = $self->get_empire_by_session($args->{session_id});
    if ($args->{on_body_id}) {
        $args->{on_body} = { body_id => $args->{on_body_id}};
    }
    my $to_body = $self->get_body($empire, $args->{to_body_id});
    my $on_body = $self->find_target($args->{on_body});
    if (not $on_body->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        confess [1009, "Can only fetch spies from a planet."];
    }
    if (not $on_body->empire_id) {
        confess [1013, "Cannot fetch spies from an uninhabited body."];
    }
    my $max_berth = $to_body->max_berth;

    # get spies
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

    # get the fleet
    my $fleet = Lacuna->db->resultset('Fleet')->find($args->{fleet_id});
    unless (defined $fleet) {
        confess [1002, "Fleet not found."];
    }
    unless ($fleet->is_available || ($fleet->can_recall && $fleet->foreign_body_id == $on_body->id)) {
        confess [1010, "That fleet is not available."];
    }

    if ($fleet->berth_level > $max_berth) {
        confess [1010, "Your spaceport level is not high enough to support a fleet with a Berth Level of ".$fleet->berth_level."."];
    }

    if (not $on_body->empire_id) {
        confess [1013, "Cannot fetch spies from an uninhabited planet."];
    }

    if (not scalar(@{$args->{spy_ids}})) {
        confess [1013, "You can't send a fleet to collect no spies."];
    }
    
    # check size
    my $no_of_ships = ceil(scalar(@{$args->{spy_ids}}) / $fleet->max_occupants);
    if ($fleet->quantity < $no_of_ships) {
        confess [1013, "The fleet cannot hold the spies selected."];
    }
    
    # send it
    $fleet = $fleet->split($no_of_ships);
    $fleet->send(
        target      => $on_body,
        payload     => { fetch_spies => \@ids_fetched },
    );

    return {
        fleet   => $fleet->get_status,
        spies_fetched      => \@ids_fetched,
        spies_not_fetched  => \@ids_not_fetched,
        status  => $self->format_status($empire, $to_body),
    };
}


sub view_travelling_fleets {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }

    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
                                                                    
    my $paging = $self->_fleet_paging_options( (defined $args->{paging} && ref $args->{paging} eq 'HASH') ? $args->{paging} : {} );
    my $filter = $self->_fleet_filter_options( (defined $args->{filter} && ref $args->{filter} eq 'HASH') ? $args->{filter} : {} );
    my $sort = $self->_fleet_sort_options( $args->{sort} // 'date_available' );

    my $attrs = {
        order_by => $sort,
    };
    $attrs->{rows} = $paging->{items_per_page} if ( defined $paging->{items_per_page} );
    $attrs->{page} = $paging->{page_number} if ( defined $paging->{page_number} );

    my $body = $building->body;

    my @travelling;
    my $fleets = $body->fleets_travelling->search($filter, $attrs);
    my $ships_travelling = 0;
    while (my $fleet = $fleets->next) {
        $fleet->body($body);
        push @travelling, $fleet->get_status;
        $ships_travelling += $fleet->quantity;
    }
    return {
        status                      => $self->format_status($empire, $body),
        number_of_fleets_travelling => $fleets->pager->total_entries,
        number_of_ships_travelling  => $ships_travelling,
        travelling                  => \@travelling,
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
    return [ "me.$sort", 'me.name' ];
}

# View all of your fleets whatever they are doing
# 
sub view_all_fleets {
    my $self = shift;
    my $args = shift;
            
    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            paging          => shift,
            filter          => shift,
            sort            => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
                                                                    
    my $paging = $self->_fleet_paging_options( (defined $args->{paging} && ref $args->{paging} eq 'HASH') ? $args->{paging} : {} );
    my $filter = $self->_fleet_filter_options( (defined $args->{filter} && ref $args->{filter} eq 'HASH') ? $args->{filter} : {} );
    my $sort = $self->_fleet_sort_options( $args->{sort} // 'type' );

    my $attrs = {
        order_by => $sort,
    };
    $attrs->{rows} = $paging->{items_per_page} if ( defined $paging->{items_per_page} );
    $attrs->{page} = $paging->{page_number} if ( defined $paging->{page_number} );

    my $body = $building->body;

    my @fleet;
    my $fleets = $body->fleets->search( $filter, $attrs );
    while (my $fleet = $fleets->next) {
        push @fleet, $fleet->get_status;
    }

    return {
        status              => $args->{no_status} ? {} : $self->format_status($empire, $body),
        number_of_fleets    => defined $paging->{page_number} ? $fleets->pager->total_entries : $fleets->count,
        fleets              => \@fleet,
    };
}


# View incoming fleets (not own returning fleets)
sub view_incoming_fleets {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            target          => shift,
            paging          => shift,
            filter          => shift,
            sort            => shift,
        };
    }

    $args->{task} = 'travelling';
    $args->{task_title} = 'incoming';
    return $self->_view_fleets($args);
}

sub view_orbiting_fleets {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            target          => shift,
            paging          => shift,
            filter          => shift,
            sort            => shift,
        };
    }

    $args->{task} = 'orbiting';
    $args->{task_title} = 'orbiting';
    return $self->_view_fleets($args);
}

sub view_mining_platforms {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            target          => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $target = $self->find_target($args->{target});
    my $platform_rs = Lacuna->db->resultset('MiningPlatforms');
    if (not $target->isa('Lacuna::DB::Result::Map::Body::Asteroid')) {
        confess [1002, 'Target is not an Asteroid.'];
    }
    $platform_rs = $platform_rs->search({
        asteroid_id     => $target->id,
        },{
        prefetch        => {planet => 'empire'},
    });
    my @platforms;
    while (my $platform = $platform_rs->next) {
        push @platforms, {
            empire_id   => $platform->planet->empire_id,
            empire_name => $platform->planet->empire->name,
        };
    }
    my %out = (
        status              => $self->format_status($empire),
        mining_platforms    => \@platforms,
    );
    return \%out;
}



sub _view_fleets {
    my ($self, $args) = @_;

    my $empire  = $self->get_empire_by_session($args->{session_id});
    # see all incoming ships from own empire, or from any alliance member
    # if the target is an allied colony, see all incoming ships dependent upon the highest
    # level of space-port on the target
    
    my $target = $self->find_target($args->{target});
    my $fleet_rs = Lacuna->db->resultset('Fleet');
    my @ally_ids = map {$_->id} $empire->allies;
    if ($args->{task} eq 'travelling') {
        $fleet_rs = $fleet_rs->search({
            task            => 'Travelling',
            direction       => 'out',
            },{
            prefetch        => 'body',
        });
    }
    if ($args->{task} eq 'orbiting') {
        $fleet_rs = $fleet_rs->search({
            task            => ['Orbit','Defend'],
            },{
            prefetch        => 'body',
        });
    }

    if ($target->isa('Lacuna::DB::Result::Map::Star')) {
        $fleet_rs = $fleet_rs->search({ foreign_star_id => $target->id });
    }
    else {
        $fleet_rs = $fleet_rs->search({ foreign_body_id => $target->id });
    }

    my $status_args;
    $status_args->{ally_ids} = \@ally_ids;
    $status_args->{own_empire_id} = $empire->id;
    if ($target->isa('Lacuna::DB::Result::Map::Planet') and $target->empire_id ~~ \@ally_ids) {
        # It is our own planet/SS or an allied one
        # so see all incoming subject to level of spaceport
        my $spaceport = $target->spaceport;
        if (defined $spaceport) {
            $status_args->{fleet_details_level} = ($spaceport->level * 350) * ( $spaceport->efficiency / 100 );
            $status_args->{fleet_from_level} = ($spaceport->level * 450) * ( $spaceport->efficiency / 100 );
        }
    }
    else {
        # otherwise only see own or allied incoming
        $fleet_rs = $fleet_rs->search({ 'body.empire_id' => \@ally_ids });
    }
    my @fleets;
    my $no_ships = 0;
    while (my $fleet = $fleet_rs->next) {
        push @fleets, $fleet->get_status($target, $status_args);
        $no_ships += $fleet->quantity;
    }
    my %out = (
        status          => $self->format_status($empire),
        $args->{task_title}   => \@fleets,
    );
    if ($args->{task_title} eq 'incoming') {
        $out{number_of_incoming_fleets} = scalar(@fleets);
        $out{number_of_incoming_ships} = $no_ships;
    }
    return \%out;
}

# rename some, or all, ships in a fleet
#
sub rename_fleet {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            fleet_id        => shift,
            name            => shift,
        };
    }

    Lacuna::Verify->new(content=>\$args->{name}, throws=>[1005, 'Invalid name for a fleet.'])
        ->not_empty
        ->no_profanity
        ->length_lt(31)
        ->only_ascii
        ->no_restricted_chars;

    my $name    = $args->{name};
    $name       =~ s/^\s+//;
    $name       =~ s/\s+$//;
    my $quantity = $args->{quantity};
    if (defined $quantity) {
        if ($quantity <= 0 or $quantity != int($quantity)) {
            confess [1009, "Quantity must be a positive integer."];
        }
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $fleet       = Lacuna->db->resultset('Fleet')->find($args->{fleet_id});
    if (not defined $fleet) {
        confess [1002, "Fleet not found."];
    }
    if (not defined $quantity) {
        $quantity = $fleet->quantity;
    }
    if ($quantity > $fleet->quantity) {
        confess [1009, "Quantity must be less than or equal to the number of ships in the fleet."];
    }
    if ($fleet->body_id != $building->body_id) {
        confess [1010, "You can't manage a fleet that is not yours."];
    }
    if ($quantity == $fleet->quantity) {
        $fleet->name($name);
        $fleet->update;
    }
    else {
        my $new_fleet = $fleet->split($quantity);
        if (not defined $new_fleet) {
            confess [1002, "Fleet not big enough."];
        }
        $new_fleet->name($name);
        $new_fleet->update;
    }
    return $self->view($args);
}

sub scuttle_fleet {
    my $self = shift;
    my $args = shift;
        
    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            fleet_id        => shift,
            quantity        => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});

    my $fleet       = Lacuna->db->resultset('Fleet')->find($args->{fleet_id});
    if (not defined $fleet) {
        confess [1002, "Fleet not found."];
    }
    my $qty = $args->{quantity};
    $fleet->has_that_quantity($qty);
    $fleet->can_scuttle;

    if ($fleet->body_id != $building->body_id) {
        confess [1013, "You can't manage a fleet that is not yours."];
    }
    if ($qty == $fleet->quantity) {
        $fleet->delete;
    }
    else {
        $fleet->quantity($fleet->quantity - $qty);
        $fleet->update;
    }
    return $self->view($args);
}

sub view_battle_logs {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
            paging          => shift,
            filter          => shift,
            sort            => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});

    my $paging = $self->_fleet_paging_options( (defined $args->{paging} && ref $args->{paging} eq 'HASH') ? $args->{paging} : {} );

    my $attrs = {
        order_by => { -desc => 'date_stamp' },
    };
    $attrs->{rows} = defined $paging->{items_per_page} ? $paging->{items_per_page} : 25;
    $attrs->{page} = defined $paging->{page_number} ? $paging->{page_number} : 1;

    my @logs;
    my $battle_logs = $building->battle_logs->search({}, $attrs);
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
    my $orig = shift;
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id}, skip_offline => 1);
                                                                
    my $out         = $orig->($self, $args->{session_id}, $args->{building_id});

    return $out unless $building->level > 0;

    # TODO Replace this with a single database query and 'group by'
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

__PACKAGE__->register_rpc_method_names(qw(
    view
    view_all_fleets
    view_incoming_fleets
    view_available_fleets
    view_unavailable_fleets
    view_orbiting_fleets
    view_mining_platforms
    send_fleet
    recall_fleet
    rename_fleet
    scuttle_fleet
    view_travelling_fleets
    prepare_send_spies
    send_spies
    prepare_fetch_spies
    fetch_spies
    view_battle_logs
));

no Moose;
__PACKAGE__->meta->make_immutable;

