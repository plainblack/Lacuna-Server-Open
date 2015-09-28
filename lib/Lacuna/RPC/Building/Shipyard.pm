package Lacuna::RPC::Building::Shipyard;

use 5.010;
use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use List::Util qw(none max min any sum reduce);

sub app_url {
    return '/shipyard';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Shipyard';
}

sub view_build_queue {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;
    $page_number ||= 1;
    my @building;
    my $ships = Lacuna->db->resultset('Ships')->search(
        { shipyard_id => $building->id, task => 'Building' },
        { order_by    => 'date_available', rows => 25, page => $page_number },
        );
    while (my $ship = $ships->next) {
        push @building, {
            id              => $ship->id,
            type            => $ship->type,
            type_human      => $ship->type_formatted,
            date_completed  => $ship->date_available_formatted,
        }
    }
    my $number_of_ships = $ships->pager->total_entries;
    return {
        status                      => $self->format_status($empire, $body),
        number_of_ships_building    => $number_of_ships,
        ships_building              => \@building,
        cost_to_subsidize           => $number_of_ships,
        building                    => {
            work        => {
                seconds_remaining   => $building->work_seconds_remaining,
                start               => $building->work_started_formatted,
                end                 => $building->work_ends_formatted,
            },
        },
    };
}


sub subsidize_build_queue {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;

    my $ships = $building->building_ships;

    my $cost = $ships->count;
    unless ($empire->essentia >= $cost) {
        confess [1011, "Not enough essentia."];    
    }

    $empire->spend_essentia({
        amount      => $cost, 
        reason      => 'ship build subsidy after the fact',
    });    
    $empire->update;

    while (my $ship = $ships->next) {
        $ship->finish_construction;
    }
    $building->finish_work->update;
 
    return $self->view($empire, $building);
}

sub delete_build {
    my ($self, $session_id, $building_id, $ship_id) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    if (!ref $ship_id)
    {
        $ship_id = [ $ship_id ];
    }
    elsif (ref $ship_id eq 'ARRAY' )
    {
        confess [1000, 'Invalid ship ID.' ]
            unless none { ref $_ } @$ship_id;
    }
    else
    {
        confess [1000, 'Invalid ship ID reference.' ];
    }

    my $ships = Lacuna->db->resultset('Ships')->search({
            id => $ship_id,
            task => 'Building',
    });
    my $cancelled_count = 0;
    while (my $ship = $ships->next)
    {
        $ship->cancel_build;
        ++$cancelled_count;
    }

    return {
        status          => $self->format_status($empire, $building->body),
        cancelled_count => $cancelled_count,
    };
}


sub subsidize_ship {
    my ($self, $args) = @_;

    if (ref($args) ne "HASH") {
        confess [1000, "You have not supplied a hash reference"];
    }
    my $empire              = $self->get_empire_by_session($args->{session_id});
    my $building            = $self->get_building($empire, $args->{building_id});
    unless ($building->effective_level > 0 and $building->efficiency == 100) {
        confess [1003, "You must have a functional Space Port!"];
    }
    my $scheduled_ship = Lacuna->db->resultset('Ships')->find({id => $args->{ship_id}});

    if (not $scheduled_ship) {
        confess [1003, "Cannot find that ship!"];
    }
    if ($scheduled_ship->shipyard_id != $building->id or $scheduled_ship->task ne 'Building') {
        confess [1003, "That ship is not in construction at this shipyard!"];
    }

    my $cost = 1;
    unless ($empire->essentia >= $cost) {
        confess [1011, "Not enough essentia."];
    }
    $empire->spend_essentia({
        amount  => $cost,
        reason  => 'ship build subsidy after the fact',
    });
    $empire->update;

    $scheduled_ship->reschedule_queue;
    $scheduled_ship->finish_construction;

    return $self->view_build_queue($empire, $building);

}


sub build_ship {
    my ($self, $session_id, $building_id, $type, $quantity) = @_;
    $quantity = defined $quantity ? $quantity : 1;
    if ($quantity > 600) { # of course, this would only be reached if the planet had 20 shipyards at level 30
        confess [1011, "You can only build up to 600 ships at a time"];
    }
    if ($quantity <= 0 or int($quantity) != $quantity) {
        confess [1001, "Quantity must be a positive integer"];
    }
    my $costs;
    my $empire      = $self->get_empire_by_session($session_id);
    my $building    = $self->get_building($empire, $building_id);
    my $body_id     = $building->body_id;

    for (1..$quantity) {
        my $ship = Lacuna->db->resultset('Ships')->new({type => $type});
        if (not defined $costs) {
            $costs = $building->get_ship_costs($ship);
            $building->can_build_ship($ship, $costs, $quantity);
        }
        $building->spend_resources_to_build_ship($costs);
        $building->build_ship($ship, $costs->{seconds});
        $ship->body_id($body_id);
        $ship->update;
    }
    return $self->view_build_queue($empire, $building);
}

# All buildings must be on the same body
# options:
#     type        - sweeper, snark3, etc.
#   one of:
#     body_id     - the planet to build on
#     building_id - the primary SY to use, or a list of SYs to use (array ref)
#   optional:
#     autoselect  -
#          "all"    - use the given body, select all SYs
#          "higher" - use the given body, select all SYs equal to or higher level than this one
#          "only"   - use the given body, select all SYs equal in level to this one
#                   - if not given, no autoselecting (just building_id(s) passed in)
#     quantity    - default 1

sub build_ships {
    my ($self, $session_id, $opts) = @_;
    my $empire = $self->get_empire_by_session($session_id);

    my $quantity = $opts->{quantity} // 1;
    if ($quantity > 600) { # of course, this would only be reached if the planet had 20 shipyards at level 30
        confess [1011, "You can only build up to 600 ships at a time"];
    }
    if ($quantity <= 0 or int($quantity) != $quantity) {
        confess [1001, "Quantity must be a positive integer"];
    }

    my @buildings;
    my $building_view;
    if ($opts->{building_id}) {
        if (ref($opts->{building_id}) eq 'ARRAY') {
            push @buildings, map { $self->get_building($empire, $_) } @{$opts->{building_id}}
        } else {
            push @buildings, $self->get_building($empire, $opts->{building_id});
        }
        $opts->{body_id} = $buildings[0]->body_id;
        $building_view = $buildings[0];
    } elsif ($opts->{body_id}) {

    } else {
        confess [1001, "Either building id(s) or body id must be provided"];
    }
    my $body = $self->get_body($empire, $opts->{body_id});
    @buildings = grep { $_->level > 0 && $_->efficiency >= 100 } @buildings;

    my @all_sys = grep {
        $_->class eq 'Lacuna::DB::Result::Building::Shipyard' &&
        $_->level > 0 && $_->efficiency >= 100
    } @{$body->building_cache};

    my $ships_building = Lacuna->db->resultset("Ships")->search({body_id => $opts->{body_id}, task => 'Building'})->count;
    if ($quantity > (my $total = sum map { $_->level } @all_sys) - $ships_building)
    {
        confess [1011, "You can only build up to $total ships at a time on this planet, and you already have $ships_building ships building."];
    }
    if (any { $_->body_id != $opts->{body_id} } @buildings)
    {
        confess [1011, "All Shipyards must be on the same planet."];
    }

    given(lc $opts->{autoselect}) {
        when([undef,'']) {
            confess [1011, 'No repaired building_id specified'] if @buildings < 1;
        }
        when('all') {
            @buildings = @all_sys;
            $building_view ||= (sort { $b->level <=> $a->level } @buildings)[0];
        }
        when('higher') {
            confess [1011, 'Too many building_ids'] if @buildings > 1;
            confess [1011, 'No building_id specified'] if @buildings < 1;
            my $min_level = $buildings[0]->level;
            @buildings = grep {
                $_->level >= $min_level
            } @all_sys;
            $building_view ||= $buildings[-1];
        }
        when('only') {
            confess [1011, 'Too many building_ids'] if @buildings > 1;
            confess [1011, 'No building_id specified'] if @buildings < 1;
            my $desired_level = $buildings[0]->level;
            @buildings = grep {
                $_->level == $desired_level
            } @all_sys;
            $building_view ||= $buildings[-1];
        }
        default {
            confess [1011, "Unknown autoselect option: $_"];
        }
    }

    my $ship_template = Lacuna->db->resultset('Ships')->new({type => $opts->{type}});
    unless ($ship_template) {
        confess [1011, "Unknown ship type: $opts->{type}"];
    }

    # different SYs may have different costs.
    my %costs;
    my $cost_for = sub {
        my $b = shift;
        $costs{$b->id} ||= $b->get_ship_costs($ship_template);
        $costs{$b->id};
    };

    # sort based on when the SY would become available.
    my $sorter = sub {
        @buildings = sort {
            ($a->work_seconds_remaining + $cost_for->($a)->{seconds}) <=>
            ($b->work_seconds_remaining + $cost_for->($b)->{seconds})
        } @buildings;
        $buildings[0];
    };

    # ensure costs can be met overall by using the highest level SY.
    # (should determine the spread of all the ships being built on their
    # appropriate SYs and add up the costs that way, but, for now, this
    # is a close enough approximation.)
    my $highest_sy = reduce { $a->level > $b->level ? $a : $b } @buildings;
    $highest_sy->can_build_ship($ship_template, $cost_for->($highest_sy), $quantity);

    #my $needs_refresh;
    for (1..$quantity) {
        my $building = $sorter->();
        my $ship = Lacuna->db->resultset('Ships')->new({type => $opts->{type}});
        my $cost = $cost_for->($building);
        $building->can_build_ship($ship, $cost, 1);
        $building->spend_resources_to_build_ship($cost);
        $building->build_ship($ship, $cost->{seconds});
        $ship->body_id($opts->{body_id});
        $ship->update;

        #$needs_refresh++ if ($building->id != $building_view->id)
    }

    #if ($needs_refresh)
    #{
    #    $body->needs_surface_refresh(1);
    #    $body->update;
    #}

    #return $self->view_build_queue($empire, $building_view);
    Lacuna::RPC::Body->new->get_buildings($empire, $body);
}


sub get_buildable {
    my ($self, $session_id, $building_id, $tag) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my %buildable;
    foreach my $type (SHIP_TYPES) {
        my $ship = Lacuna->db->resultset('Ships')->new({type=>$type});
        my @tags = @{$ship->build_tags};
        if ($tag) {
            next unless ($tag ~~ \@tags);
        }
        my $can = eval{$building->can_build_ship($ship)};
        my $reason = $@;
        $buildable{$type} = {
            attributes  => {
                speed           => $building->set_ship_speed($ship),
                stealth         => $building->set_ship_stealth($ship),
                hold_size       => $building->set_ship_hold_size($ship),
                berth_level     => $ship->base_berth_level,
                combat          => $building->set_ship_combat($ship),
                max_occupants   => $ship->max_occupants
            },
            tags        => \@tags,
            cost        => $building->get_ship_costs($ship),
            can         => ($can) ? 1 : 0,
            reason      => $reason,
            type_human  => $ship->type_formatted,
            image       => $ship->image,
        };
    }
    my $docks = 0;
    my $port = $building->body->spaceport;
    if (defined $port) {
        $docks = $port->docks_available;
    }
    my $max_ships = $building->max_ships;
    my $total_ships_building = Lacuna->db->resultset('Ships')->search({body_id => $building->body_id, task=>'Building'})->count;

    return {
        buildable       => \%buildable,
        docks_available => $docks,
        build_queue_max => $max_ships,
        build_queue_used => $total_ships_building,
        status          => $self->format_status($empire, $building->body),
        };
}


__PACKAGE__->register_rpc_method_names(qw(
    get_buildable 
    build_ship 
    build_ships
    view_build_queue 
    subsidize_build_queue
    subsidize_ship
));


no Moose;
__PACKAGE__->meta->make_immutable;

