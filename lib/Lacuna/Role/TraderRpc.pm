package Lacuna::Role::TraderRpc;

use Moose::Role;
use feature "switch";
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);
use Lacuna::Util qw(randint);

sub view_my_market {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    $page_number ||=1;
    my $my_trades = $building->my_market->search(undef, { rows => 25, page => $page_number });
    my @trades;
    while (my $trade = $my_trades->next) {
        push @trades, {
            id                      => $trade->id,
            date_offered            => $trade->date_offered_formatted,
            ask                     => $trade->ask,
            offer                   => $trade->format_description_of_payload,
        };
    }
    return {
        trades      => \@trades,
        trade_count => $my_trades->pager->total_entries,
        page_number => $page_number,
        status      => $self->format_status($empire, $building->body),
    };
}



sub view_market {
    my ($self, $session_id, $building_id, $page_number, $filter) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    $page_number ||=1;
    my $all_trades = $building->available_market->search(
        undef,{
            rows        => 25, 
            page        => $page_number, 
            join        => 'body', 
            order_by    => 'ask',
        }
    );
    if ($filter && $filter ~~ [qw(food ore water waste energy glyph prisoner ship plan)]) {
        $all_trades = $all_trades->search({ 'has_'.$filter => 1 });
    }
    my @trades;
    while (my $trade = $all_trades->next) {
        if ($trade->body->empire_id eq '') {
            $trade->delete;
            next;
        }
        my $delivery;
        if ($trade->transfer_type eq 'transporter') {
            $delivery = {duration => 0};
        }
        else {
            $delivery = {duration => $trade->ship->calculate_travel_time($building->body)};
        }
        push @trades, {
            id              => $trade->id,
            date_offered    => $trade->date_offered_formatted,
            ask             => $trade->ask,
            offer           => $trade->format_description_of_payload,
            body => {
                id          => $trade->body_id,
            },
            empire => {
                id          => $trade->body->empire->id,
                name        => $trade->body->empire->name,
            },
            delivery =>     => $delivery,
        };
    }
    return {
        trades      => \@trades,
        trade_count => $all_trades->pager->total_entries,
        page_number => $page_number,
        status      => $self->format_status($empire, $building->body),
    };
}


sub get_ships {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {body_id => $building->body_id, task => 'docked'},
        {order_by => [ 'type', 'hold_size', 'speed']}
        );
    my @out;
    while (my $ship = $ships->next) {
        push @out, {
            id          => $ship->id,
            name        => $ship->name,
            type        => $ship->type,
            hold_size   => $ship->hold_size,
            berth_level => $ship->berth_level,
            speed       => $ship->speed,
        };
    }
    return {
        ships                   => \@out,
        cargo_space_used_each   => 50_000,
        status                  => $self->format_status($empire, $building->body),
    };
}

sub get_ship_summary {
    my ($self, $session_id, $building_id) = @_;

    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {body_id => $building->body_id, task => 'docked'},
        {order_by => [ 'type', 'hold_size', 'speed']}
        );
    my $ship_summary = {};
    while (my $ship = $ships->next) {
        my $key = sprintf("%s~%s~%02u~%02u~%02u", $ship->name, $ship->type, $ship->hold_size, $ship->berth_level, $ship->speed);
        $ship_summary->{$key}++;
    }

    # Sort
    my @ships = map { {$_ => $ship_summary->{$_}} } sort {$a cmp $b} keys %$ship_summary;

    my @out;
    for my $ship (@ships) {
        my ($key,$quantity) = %$ship;
        my ($name,$type,$hold_size,$berth_level,$speed) = split /~/, $key;

        push @out, {
            name        => $name,
            type        => $type,
            hold_size   => int($hold_size),
            berth_level => int($berth_level),
            speed       => int($speed),
            quantity    => $quantity,
        };
    }
    return {
        ships                   => \@out,
        cargo_space_used_each   => 50_000,
        status                  => $self->format_status($empire, $building->body),
    };
}


sub get_prisoners {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $dt_parser = Lacuna->db->storage->datetime_parser;
    my $now = $dt_parser->format_datetime( DateTime->now );

    my $prisoners = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
        { on_body_id => $building->body_id, task => 'Captured', available_on => { '>' => $now } },
        {order_by => [ 'name' ]}
        );
    my @out;
    while (my $prisoner = $prisoners->next) {
        push @out, {
            id          => $prisoner->id,
            name        => $prisoner->name,
            level       => $prisoner->level,
            sentence_expires => $prisoner->format_available_on,
        };
    }
    return {
        prisoners               => \@out,
        cargo_space_used_each   => 350,
        status                  => $self->format_status($empire, $building->body),
    };
}

sub get_plan_summary {
    my ($self, $session_id, $building_id) = @_;

    return $self->get_plans($session_id, $building_id);
}


sub get_plans {
    my ($self, $session_id, $building_id) = @_;

    my $empire      = $self->get_empire_by_session($session_id);
    my $building    = $self->get_building($empire, $building_id);

    my @out;
    my $sorted_plans = $building->body->sorted_plans;
    foreach my $plan (@$sorted_plans) {
        my $plan_type = $plan->class;
        $plan_type =~ s/Lacuna::DB::Result::Building:://;
        $plan_type =~ s/::/_/g;
        push @out, {
            name                => $plan->class->name,
            plan_type           => $plan_type,
            level               => int($plan->level),
            extra_build_level   => int($plan->extra_build_level),
            quantity            => $plan->quantity,
        };
    }
    return {
        plans                   => \@out,
        cargo_space_used_each   => 1_000,
        status                  => $self->format_status($empire, $building->body),
    };
}

sub get_glyph_summary {
    my ($self, $session_id, $building_id) = @_;

    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my @glyphs   = sort {$a->type cmp $b->type} $building->body->glyph->all;

    my @out;
    foreach my $glyph (@glyphs) {
        push @out, {
            id       => $glyph->id,
            name     => $glyph->type,
            type     => $glyph->type,
            quantity => $glyph->quantity,
        };
    }

    return {
        glyphs                  => \@out,
        cargo_space_used_each   => 100,
        status                  => $self->format_status($empire, $building->body),
    };
}


sub get_stored_resources {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my @types = (FOOD_TYPES, ORE_TYPES, qw(water waste energy));
    my %out;
    my $body = $building->body;
    foreach my $type (@types) {
        my $stored = $body->type_stored($type);
        next if $stored < 1;
        $out{$type} = $stored;
    }
    return {
        resources               => \%out,
        cargo_space_used_each   => 1,
        status                  => $self->format_status($empire, $body),
    };
}


sub report_abuse {
    my ($self, $session_id, $building_id, $trade_id) = @_;
    unless ($trade_id) {
        confess [1002, 'You have not specified a trade to report.'];
    }
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $cache = Lacuna->cache;
    if ($cache->get('trade_lock', $trade_id)) {
        confess [1013, 'A buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    my $times_reporting = $cache->increment('empire_reporting_trade_abuse'.DateTime->now->day, $empire->id, 1, 60 * 60 * 24);
    if ($times_reporting > 10) {
        confess [1010, 'You have reported enough abuse for one day.'];
    }
    my $reports = $cache->increment('trade_abuse',$trade_id,1, 60 * 60 * 24 * 3);
    if ($reports >= 5) {
        my $trade = $building->market->find($trade_id);
        if (defined $trade) {
            $trade->body->empire->send_predefined_message(
                filename    => 'trade_abuse.txt',
                params      => [join("\n",@{$trade->format_description_of_payload}), $trade->ask.' essentia'],
                tags        => ['Trade','Alert'],
            );
            $trade->withdraw($trade->body);
        }
        return {
            status      => $self->format_status($empire, $building->body),
        };
    }
}


1;


