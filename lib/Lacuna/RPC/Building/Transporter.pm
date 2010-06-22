package Lacuna::RPC::Building::Transporter;

use Moose;
extends 'Lacuna::RPC::Building';

with 'Lacuna::Role::TraderRpc';

sub app_url {
    return '/transporter';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Transporter';
}

sub add_trade {
    my ($self, $session_id, $building_id, $offer, $ask) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($empire->essentia >= 1) {
        confess [1011, "You need 1 essentia to make a trade using the Subspace Transporter."];
    }
    my $trade = $building->add_trade($offer, $ask);
    $empire->spend_essentia(1, 'Offered Transporter Trade')->update;
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
    $empire->add_essentia(1,'Withdrew Transporter Trade')->update;
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
    my $trade = $building->trades->find($trade_id);
    unless (defined $trade) {
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.'];
    }
    unless ($building->determine_available_cargo_space >= $trade->ask_quantity) {
        confess [1011, 'Your transporter is not capable of a load this size.'];
    }
    my $body = $building->body;
    if ($trade->ask_type eq 'essentia') {
        unless ($empire->essentia >= $trade->ask_quantity + 1) {
            confess [1011, 'You need at least '.($trade->ask_quantity + 1).' essentia to make this trade.']
        }
        $empire->spend_essentia($trade->ask_quantity + 1, 'Trade Price and Transporter Cost')->update;
        $trade->body->empire->add_essentia($trade->ask_quantity, 'Trade Income')->update;
    }
    else {
        my $stored = $trade->ask_type.'_stored';
        unless ($empire->essentia >= 1) {
            confess [1011, 'You need at least 1 essentia to make this trade.']
        }
        unless ($body->$stored >= $trade->ask_quantity) {
            confess [1011, 'You need at least '.$trade->ask_quantity.' '.$body->ask_type.' to make this trade.'];
        }
        $empire->spend_essentia(1, 'Transporter Cost')->update;
        my $spend = 'spend_'.$trade->ask_type;
        $body->$spend($trade->ask_quantity);
        my $add = 'add_'.$trade->ask_type;
        $trade->body->$add($trade->ask_quantity);
    }
    $trade->unload($body);
    $trade->delete;
    $body->update;
    $trade->body->update;
    return {
        status      => $self->format_status($empire, $building->body),
    };
}

__PACKAGE__->register_rpc_method_names(qw(add_trade withdraw_trade accept_trade));


no Moose;
__PACKAGE__->meta->make_immutable;

