package Lacuna::RPC::Building::MercenariesGuild;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building::Trade';
use Guard;

with 'Lacuna::Role::SpyTraderRpc';

sub app_url {
    return '/mercenariesguild';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::MercenariesGuild';
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
    my $cost = sprintf "%.1f", 3 - $building->level * 0.1;
    $empire->add_essentia($cost, 'Withdrew Mercenary Trade')->update;
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
    confess [1013, 'You cannot use a mercenaries guild that has not yet been built.'] unless $building->level > 0;

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

    $empire->spend_essentia($trade->ask, 'Trade Price')->update;
    $trade->body->empire->add_essentia($trade->ask, 'Trade Income')->update;
    #my $cargo_log = Lacuna->db->resultset('Lacuna::DB::Result::Log::Cargo');
    #$cargo_log->new({
    #    message     => 'mercenaries guild offer accepted',
    #    body_id     => $trade->body_id,
    #    data        => $trade->payload,
    #    object_type => ref($trade),
    #    object_id   => $trade->id,
    #})->insert;
    $offer_ship->send(
        target  => $body,
        payload => $trade->payload,
    );
    #$cargo_log->new({
    #    message     => 'send offer',
    #    body_id     => $offer_ship->foreign_body_id,
    #    data        => $offer_ship->payload,
    #    object_type => ref($offer_ship),
    #    object_id   => $offer_ship->id,
    #})->insert;
    
    $trade->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'trade_accepted.txt',
        params      => [join("; ",@{$trade->format_description_of_payload}), $trade->ask.' essentia', $empire->id, $empire->name],
    );
    $trade->delete;

    return {
        status      => $self->format_status($empire, $building->body),
    };
}

sub add_to_market {
    my ($self, $session_id, $building_id, $offer, $ask, $options) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    confess [1013, 'You cannot use a mercenaries guild that has not yet been built.'] unless $building->level > 0;
    my $cost = sprintf "%.1f", 3 - $building->level * 0.1;
    unless ($empire->essentia >= $cost) {
        confess [1011, "You need $cost essentia to make a trade using the Mercenaries Guild."];
    }
    $empire->spend_essentia($cost, 'Offered Mercenaries Trade')->update;
    my $trade = $building->add_to_market($offer, $ask, $options);
    return {
        trade_id    => $trade->id,
        status      => $self->format_status($empire, $building->body),
    };
}

__PACKAGE__->register_rpc_method_names(qw(report_abuse view_my_market view_market accept_from_market withdraw_from_market add_to_market push_items get_trade_ships get_spies));


no Moose;
__PACKAGE__->meta->make_immutable;

