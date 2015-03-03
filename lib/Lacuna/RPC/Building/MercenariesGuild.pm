package Lacuna::RPC::Building::MercenariesGuild;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Guard;

sub app_url {
    return '/mercenariesguild';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::MercenariesGuild';
}

sub get_trade_ships {
    my ($self, $session_id, $building_id, $target_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target_id) if $target_id;
    my @ships;
    my $ships = $building->trade_ships;
    while (my $ship = $ships->next) {
        push @ships, $ship->get_status($target);
    }
    return {
        status      => $self->format_status($empire, $building->body),
        ships       => \@ships,
    };
}

sub withdraw_from_market {
    my ($self, $session_id, $building_id, $trade_id) = @_;
    unless ($trade_id) {
        confess [1002, 'You have not specified a trade to withdraw.'];
    }
    my $cache = Lacuna->cache;
    if ($cache->get('trade_lock', $trade_id)) {
        confess [1013, 'A buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    $cache->set('trade_lock',$trade_id,1,5);
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $trade = $building->market->find($trade_id);
    unless (defined $trade) {
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.'];
    }
    $trade->withdraw($building->body);
    return {
        status      => $self->format_status($empire, $building->body),
    };
}

sub accept_from_market {
    my ($self, $session_id, $building_id, $trade_id) = @_;
    unless ($trade_id) {
        confess [1002, 'You have not specified a trade to accept.'];
    }
    my $cache = Lacuna->cache;
    if ($cache->get('trade_lock', $trade_id)) {
        confess [1013, 'Another buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    $cache->set('trade_lock',$trade_id,1,5);
    my $guard = guard {
        $cache->delete('trade_lock',$trade_id);
    };

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    confess [1013, 'You cannot use a mercenaries guild that has not yet been built.'] unless $building->effective_level > 0;
    confess [1013, 'You cannot use a mercenaries guild that is not fully operational.'] unless $building->effective_efficiency == 100;

    my $int_min = $building->body->get_building_of_class('Lacuna::DB::Result::Building::Intelligence');
    unless (defined($int_min) and $int_min->spy_count < $int_min->max_spies) {
        confess [1009, 'You are already at the maximum number of spies for the Intelligence Ministry.'];
    }

    $empire->current_session->check_captcha;

    my $trade = $building->market->find($trade_id);
    unless (defined $trade) {
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.',$trade_id];
    }
    my $offer_ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($trade->ship_id);
    unless (defined $offer_ship) {
        $trade->withdraw;
        confess [1009, 'Trade no longer available.'];
    }

    my $body = $building->body;
    unless ($empire->essentia >= $trade->ask) {
        confess [1011, 'You need at least '.$trade->ask.' essentia to make this trade.']
    }

    $guard->cancel;

    if ($trade->body->empire->id != $empire->id) {
        $empire->transfer_essentia({
            amount      => $trade->ask,
            from_reason => 'Mercenary Price',
            to_empire   => $trade->body->empire,
            to_reason   => 'Mercenary Income',
        });
        $empire->update;
    }
    
    $offer_ship->send(
        target  => $body,
        payload => $trade->payload,
    );
    my $id = $trade->payload->{mercenary};
    my $spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($id);
    if (defined($spy)) {
        $spy->empire_id($body->empire_id);
        $spy->from_body_id($body->id);
        $spy->on_body_id($body->id);
        $spy->update;
    }
    
    if ($trade->body->empire->id != $empire->id) {
        # Don't notify yourself
        $trade->body->empire->send_predefined_message(
            tags        => ['Trade','Alert'],
            filename    => 'trade_accepted.txt',
            params      => [join("\n",@{$trade->format_description_of_payload}),  $trade->ask.' essentia', $empire->id, $empire->name],
        );
    }
    $trade->delete;

    return {
        status      => $self->format_status($empire, $building->body),
    };
}

sub add_to_market {
    my ($self, $session_id, $building_id, $spy_id, $ask, $ship_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    confess [1013, 'You cannot use a mercenaries guild that has not yet been built.'] unless $building->effective_level > 0;
    my $cost = sprintf "%.1f", 3 - $building->effective_level * 0.1;
    unless ($empire->essentia >= $cost) {
        confess [1011, "You need $cost essentia to make a trade using the Mercenaries Guild."];
    }
    my $trade = $building->add_to_market($cost, $spy_id, $ask, $ship_id);
    $empire->spend_essentia({
        amount      => $cost,
        reason      => 'Offered Mercenary Trade',
    });
    $empire->update;
    return {
        trade_id    => $trade->id,
        status      => $self->format_status($empire, $building->body),
    };
}

sub view_my_market {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
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
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||=1;
    my $all_trades = $building->available_market->search(
        undef,
        { rows => 25, page => $page_number, join => 'body', order_by => 'ask' }
    );
    my @trades;
    while (my $trade = $all_trades->next) {
        if ($trade->body->empire_id eq '') {
            $trade->delete;
            next;
        }
        push @trades, {
            id                      => $trade->id,
            date_offered            => $trade->date_offered_formatted,
            ask                     => $trade->ask,
            offer                   => $trade->format_description_of_payload,
            body                    => {
                id      => $trade->body_id,
            },
            empire                  => {
                id      => $trade->body->empire->id,
                name    => $trade->body->empire->name,
            },
        };
    }
    return {
        trades      => \@trades,
        trade_count => $all_trades->pager->total_entries,
        page_number => $page_number,
        status      => $self->format_status($empire, $building->body),
    };
}

sub get_spies {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
        { empire_id => $empire->id, on_body_id => $building->body_id, task => { in => ['Counter Espionage','Idle'] } },
        {
            # match the order_by in L::RPC::B::Intelligence::view_spies
            order_by => {
                -asc => [ qw/name id/ ],
            }
        },
    );
    my @out;
    while (my $spy = $spies->next) {
        push @out, {
            id          => $spy->id,
            name        => $spy->name,
            level       => $spy->level,
        };
    }
    return {
        spies                   => \@out,
        status                  => $self->format_status($empire, $building->body),
    };
}

sub report_abuse {
    my ($self, $session_id, $building_id, $trade_id) = @_;
    unless ($trade_id) {
        confess [1002, 'You have not specified a trade to withdraw.'];
    }
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
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
__PACKAGE__->register_rpc_method_names(qw(report_abuse view_my_market view_market accept_from_market withdraw_from_market add_to_market get_trade_ships get_spies));


no Moose;
__PACKAGE__->meta->make_immutable;

