package Lacuna::RPC::Building::Transporter;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Guard;

with 'Lacuna::Role::TraderRpc','Lacuna::Role::Ship::Trade';

sub app_url {
    return '/transporter';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Transporter';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id, skip_offline => 1 });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;

    my $out = $orig->($self, $session, $building);

    my $bodies = Lacuna->db->resultset('Map::Body')->
        search(
               {
                   'me.id' => { '!=' => $session->current_body->id },
                   'me.empire_id' => $empire->id,
                   # can only push to other SSTs, that are finished building
                   # and aren't completely broken down.
                   '_buildings.class' => 'Lacuna::DB::Result::Building::Transporter',
                   '_buildings.level'      => { '>' => 0 },
                   '_buildings.efficiency' => { '>' => 0 },
               },
               {
                   join => '_buildings',
                   order_by => 'me.name',
                   '+select' => {count => '_buildings.id'},
                   '+as' => 'count_sst',
                   group_by => 'me.id',
                   having => { 'count(_buildings.id)' => { '>' => 0 } }
               }
              );

    $out->{transport}{pushable} = [];
    while (my $body = $bodies->next)
    {
        push @{$out->{transport}{pushable}}, {
            name => $body->name,
            id   => $body->id,
            x    => $body->x,
            y    => $body->y, #,,,
            zone => $body->zone,
        };
    }

    $out->{transport}{max} = $building->determine_available_cargo_space;
    return $out;
};

sub push_items {
    my ($self, $session_id, $building_id, $target_id, $items) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id});
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    confess [1013, 'You cannot use a transporter that has not yet been built.'] unless $building->effective_level > 0;
    my $cache = Lacuna->cache;
    if (! $cache->add('trade_add_lock', $building_id, 1, 5)) {
        confess [1013, 'You have a trade setup in progress.  Please wait a few moments and try again.'];
    }
    my $guard = guard {
        $cache->delete('trade_add_lock',$building_id);
    };
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
    unless ($target->empire_id == $empire->id || ($target->class eq 'Lacuna::DB::Result::Map::Body::Planet::Station' && $target->alliance_id == $empire->alliance_id)) {
        confess [1010, 'You cannot push items to a planet that is not your own.'];
    }
    my $transporter = $target->get_building_of_class('Lacuna::DB::Result::Building::Transporter');
    unless (defined $transporter) {
        confess [1010, 'You cannot push items to a planet that does not have a transporter.'];
    }
    $building->push_items($target, $transporter, $items);
    $empire->spend_essentia({
        amount  => 2, 
        reason  => 'Transporter Push',
    });
    $empire->update; # has to go after due to validation in push_goods
    return {
        status      => $self->format_status($empire, $building->body),
    };
}

sub add_to_market {
    my ($self, $session_id, $building_id, $offer, $ask) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    confess [1013, 'You cannot use a transporter that has not yet been built.'] unless $building->effective_level > 0;
    my $cache = Lacuna->cache;
    if (! $cache->add('trade_add_lock', $building_id, 1, 5)) {
        confess [1013, 'You have a trade setup in progress.  Please wait a few moments and try again.'];
    }
    my $guard = guard {
        $cache->delete('trade_add_lock',$building_id);
    };
    unless ($empire->essentia >= 1) {
        confess [1011, "You need 1 essentia to make a trade using the Subspace Transporter."];
    }
    my $trade = $building->add_to_market($offer, $ask);
    $empire->spend_essentia({
        amount  => 1, 
        reason  => 'Offered Transporter Trade',
    });
    $empire->update;
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
    if (! $cache->add('trade_lock', $trade_id, 1, 5)) {
        confess [1013, 'A buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
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
    if (! $cache->add('trade_lock', $trade_id, 1, 5)) {
        confess [1013, 'Another buyer has placed an offer on this trade. Please wait a few moments and try again.'];
    }
    my $guard = guard {
        $cache->delete('trade_lock',$trade_id);
    };

    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    confess [1013, 'You cannot use a transporter that has not yet been built.'] unless $building->effective_level > 0;

    $empire->current_session->check_captcha;

    my $trade = $building->market->find($trade_id);
    unless (defined $trade) {
        confess [1002, 'Could not find that trade. Perhaps it has already been accepted.', $trade_id];
    }
    unless ($building->determine_available_cargo_space >= $trade->ask) {
        confess [1011, 'This transporter has a maximum load size of '.$building->determine_available_cargo_space.'.'];
    }

    $self->check_payload_ships_id($trade->payload->{ships}, $building->body);

    my $body = $building->body;
    unless ($empire->essentia >= $trade->ask + 1) {
        confess [1011, 'You need '.($trade->ask + 1).' essentia to make this trade.']
    }


    $guard->cancel;

    $empire->transfer_essentia({
        amount      => $trade->ask,
        from_reason => 'Trade Price',
        to_empire   => $trade->body->empire,
        to_reason   => 'Trade Income',
    });
    $empire->spend_essentia({
        amount  => 1, 
        reason  => 'Transporter Cost',
    });
    $empire->update;

    $trade->body->empire->send_predefined_message(
        tags        => ['Trade','Alert'],
        filename    => 'trade_accepted.txt',
        params      => [join("; ",@{$trade->format_description_of_payload}), $trade->ask.' essentia', $empire->id, $empire->name],
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
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    confess [1013, 'You cannot use a transporter that has not yet been built.'] unless $building->effective_level > 0;
    $building->trade_one_for_one($have, $want, $quantity);
    return {
        status      => $self->format_status($empire, $building->body),
    };
}

__PACKAGE__->register_rpc_method_names(qw(report_abuse view_my_market view_market accept_from_market withdraw_from_market add_to_market push_items trade_one_for_one get_stored_resources get_ships get_ship_summary get_prisoners get_plan_summary get_glyph_summary));

no Moose;
__PACKAGE__->meta->make_immutable;

