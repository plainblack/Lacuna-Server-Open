package Lacuna::RPC::Building::Trade;

use Moose;
extends 'Lacuna::RPC::Building';

with 'Lacuna::Role::TraderRpc';

sub app_url {
    return '/trade';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Trade';
}

sub push_items {
    my ($self, $session_id, $building_id, $target_id, $items) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($target_id) {
        confess [1002, "You must specify a target body id."];
    }
    my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target_id);
    unless (defined $target) {
        confess [1002, 'The target body you specified could not be found.'];
    }
    unless ($target->empire_id eq $empire->id) {
        confess [1010, 'You cannot push items to a planet that is not your own.'];
    }
    $building->push_items($target, $items);
    return {
        status      => $self->format_status($empire, $building->body),
    };
}

sub add_trade {
    my ($self, $session_id, $building_id, $offer, $ask) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $trade = $building->add_trade($offer, $ask);
    return {
        trade_id    => $trade->id,
        status      => $self->format_status($empire, $building->body),
    };
}

sub withdraw_trade {
    my ($self, $session_id, $building_id, $trade_id) = @_;
    my $cache = Lacuna->cache;
    if ($cache->get('trade_lock', $trade_id)) {
        confess [1013, 'A buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    $cache->set('trade_lock',$trade_id,5);
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $trade = $building->trades->find($trade_id);
    unless (defined $trade) {
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.'];
    }
    $trade->withdraw;
    return {
        status      => $self->format_status($empire, $building->body),
    };
}

sub accept_trade {
    my ($self, $session_id, $building_id, $trade_id, $guid, $solution) = @_;
    my $cache = Lacuna->cache;
    if ($cache->get('trade_lock', $trade_id)) {
        confess [1013, 'Another buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    $cache->set('trade_lock',$trade_id,5);
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->validate_captcha($empire, $guid, $solution);
    my $ship = $building->next_available_trade_ship;
    unless (defined $ship) {
        confess [1011, 'You do not have a ship available to transport cargo.'];
    }
    my $trade = $building->trades->find($trade_id);
    unless (defined $trade) {
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.'];
    }
    unless ($ship->hold_size >= $trade->ask_quantity) {
        confess [1011, 'You need a cargo ship with a hold size of at least '.$trade->ask_quantity];
    }
    my $body = $building->body;
    if ($trade->ask_type eq 'essentia') {
        unless ($empire->essentia >= $trade->ask_quantity) {
            confess [1011, 'You need at least '.$trade->ask_quantity.' essentia to make this trade.']
        }
        $empire->spend_essentia($trade->ask_quantity, 'Trade Price')->update;
        $ship->send(
            target  => $trade->body,
            payload => { essentia => $trade->ask_quantity },
        );
    }
    else {
        my $stored = $trade->ask_type.'_stored';
        unless ($body->$stored >= $trade->ask_quantity) {
            confess [1011, 'You need at least '.$trade->ask_quantity.' '.$body->ask_type.' to make this trade.'];
        }
        my $spend = 'spend_'.$trade->ask_type;
        $body->$spend($trade->ask_quantity)->update;
        $ship->send(
            target  => $trade->body,
            payload => { resources => { $trade->ask_type => $trade->ask_quantity }}
        )
    }
    
    $building->trade_ships->find($trade->ship_id)->send(
        target  => $body,
        payload => $trade->payload,
    );
    
    $trade->delete;

    return {
        status      => $self->format_status($empire, $building->body),
    };
}

__PACKAGE__->register_rpc_method_names(qw(push_items get_stored_resources add_trade withdraw_trade accept_trade view_my_trades view_available_trades get_ships get_prisoners get_plans));


no Moose;
__PACKAGE__->meta->make_immutable;

