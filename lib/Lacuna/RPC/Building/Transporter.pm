package Lacuna::RPC::Building::Transporter;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

with 'Lacuna::Role::TraderRpc';

sub app_url {
    return '/transporter';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Transporter';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
    $out->{transport}{max} = $building->determine_available_cargo_space;
    return $out;
};

sub push_items {
    my ($self, $session_id, $building_id, $target_id, $items) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($empire->essentia >= 2) {
        confess [1011, "You need 2 essentia to push items using the Subspace Transporter."];
    }
    unless ($target_id) {
        confess [1002, "You must specify a target body id."];
    }
    my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target_id);
    unless (defined $target) {
        confess [1002, 'The target body you specified could not be found.'];
    }
    unless ($target->empire_id == $empire->id) {
        confess [1010, 'You cannot push items to a planet that is not your own.'];
    }
    my $transporter = $target->get_building_of_class('Lacuna::DB::Result::Building::Transporter');
    unless (defined $transporter) {
        confess [1010, 'You cannot push items to a planet that does not have a transporter.'];
    }
    $building->push_items($target, $transporter, $items);
    $empire->spend_essentia(2, 'Transporter Push')->update; # has to go after due to validation in push_goods
    return {
        status      => $self->format_status($empire, $building->body),
    };
}

sub add_to_market {
    my ($self, $session_id, $building_id, $offer, $ask) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    unless ($empire->essentia >= 1) {
        confess [1011, "You need 1 essentia to make a trade using the Subspace Transporter."];
    }
    my $trade = $building->add_to_market($offer, $ask);
    $empire->spend_essentia(1, 'Offered Transporter Trade')->update;
    return {
        trade_id    => $trade->id,
        status      => $self->format_status($empire, $building->body),
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
    $cache->set('trade_lock',$trade_id,5);
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
    my ($self, $session_id, $building_id, $trade_id, $guid, $solution) = @_;
    unless ($trade_id) {
        confess [1002, 'You have not specified a trade to accept.'];
    }
    my $cache = Lacuna->cache;
    if ($cache->get('trade_lock', $trade_id)) {
        confess [1013, 'Another buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    $cache->set('trade_lock',$trade_id,1,5);
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->validate_captcha($empire, $guid, $solution, $trade_id);
    my $trade = $building->market->find($trade_id);
    unless (defined $trade) {
        $cache->delete('trade_lock',$trade_id);
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.', $trade_id];
    }
    unless ($building->determine_available_cargo_space >= $trade->ask) {
        $cache->delete('trade_lock',$trade_id);
        confess [1011, 'This transporter has a maximum load size of '.$building->determine_available_cargo_space.'.'];
    }
    my $body = $building->body;
    unless ($empire->essentia >= $trade->ask + 1) {
        $cache->delete('trade_lock',$trade_id);
        confess [1011, 'You need '.($trade->ask + 1).' essentia to make this trade.']
    }
    $empire->spend_essentia($trade->ask + 1, 'Trade Price and Transporter Cost')->update;
    $trade->body->empire->add_essentia($trade->ask, 'Trade Income')->update;
    my $cargo_log = Lacuna->db->resultset('Lacuna::DB::Result::Log::Cargo');
    $cargo_log->new({
        message     => 'transporter offer accepted',
        body_id     => $trade->body_id,
        data        => $trade->payload,
        object_type => ref($trade),
        object_id   => $trade->id,
    })->insert;
    $trade->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'trade_accepted.txt',
        params      => [join("; ",@{$trade->format_description_of_payload}), $trade->ask.' essentia'],
    );
    $trade->unload($body);
    $trade->delete;
    $body->update;
    $trade->body->update;
    return {
        status      => $self->format_status($empire, $building->body),
    };
}


sub trade_one_for_one {
    my ($self, $session_id, $building_id, $have, $want, $quantity) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->trade_one_for_one($have, $want, $quantity);
    return {
        status      => $self->format_status($empire, $building->body),
    };
}

__PACKAGE__->register_rpc_method_names(qw(report_abuse view_my_market view_market accept_from_market withdraw_from_market add_to_market push_items trade_one_for_one get_stored_resources get_ships get_prisoners get_plans get_glyphs));

no Moose;
__PACKAGE__->meta->make_immutable;

