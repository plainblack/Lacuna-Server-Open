package Lacuna::DB::Result::Building::Trade;

use Moose;
use List::Util qw(max min);
use Carp;

use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

with 'Lacuna::Role::Trader','Lacuna::Role::Ship::Trade';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships Trade));
};

use constant controller_class => 'Lacuna::RPC::Building::Trade';

use constant max_instances_per_planet => 1;

use constant university_prereq => 5;

use constant image => 'trade';

use constant name => 'Trade Ministry';

use constant food_to_build => 75;

use constant energy_to_build => 75;

use constant ore_to_build => 75;

use constant water_to_build => 75;

use constant waste_to_build => 80;

use constant time_to_build => 150;

use constant food_consumption => 5;

use constant energy_consumption => 28;

use constant ore_consumption => 2;

use constant water_consumption => 5;

use constant waste_production => 1;

sub waste_chains {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::WasteChain')->search({ planet_id => $self->body_id });
}

sub supply_ships {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ body_id => $self->body_id, task => 'Supply Chain' });
}

sub waste_ships {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ body_id => $self->body_id, task => 'Waste Chain' });
}

sub max_chains {
    my $self = shift;
    return ceil($self->level);
}

sub add_waste_ship {
    my ($self, $ship) = @_;
    $ship->task('Waste Chain');
    $ship->update;
    $self->recalc_waste_production;
    return $self;
}

sub add_supply_ship {
    my ($self, $ship) = @_;
    $ship->task('Supply Chain');
    $ship->update;
    $self->recalc_supply_production;
    return $self;
}

sub send_waste_ship_home {
    my ($self, $star, $ship) = @_;
    $ship->send(
        target      => $star,
        direction   => 'in',
        task        => 'Travelling',
    );
    $self->recalc_waste_production;
    return $self;
}

sub send_supply_ship_home {
    my ($self, $planet, $ship) = @_;
    $ship->send(
        target      => $planet,
        direction   => 'in',
        task        => 'Travelling',
    );
    $self->recalc_supply_production;
    return $self;
}

sub add_waste_chain {
    my ($self, $star, $waste_hour) = @_;
    Lacuna->db->resultset('Lacuna::DB::Result::WasteChain')->new({
        planet_id   => $self->body_id,
        star_id     => $star->id,
        waste_hour  => $waste_hour,
    })->insert;
    $self->recalc_waste_production;
    return $self;
}

sub remove_waste_chain {
    my ($self, $waste_chain) = @_;
    if ($self->waste_chains->count == 1) {
        my $ships = $self->waste_ships;
        while (my $ship = $ships->next) {
            $self->send_waste_ship_home($waste_chain->star, $ship);
        }
    }
    $waste_chain->delete;
    $self->recalc_waste_production;
    return $self;
}

sub recalc_waste_production {
    my ($self) = @_;
    my $body = $self->body;

    my $ship_speed = 0;
    my $ship_capacity = 0;
    my $ships = $self->waste_ships;
    while (my $ship = $ships->next) {
        $ship_capacity += $ship->hold_size;
        $ship_speed += $ship->speed;
    }

    my $waste_chain_count   = $self->waste_chains->count;
    my $waste_chains        = $self->waste_chains;
    my $waste_hour          = 0;
    my $distance            = 0;
    while (my $waste_chain = $waste_chains->next) {
        $distance += $body->calculate_distance_to_target($waste_chain->star);
        $waste_hour += $waste_chain->waist_hour;
    }
    $distance *= 2;
carp "RECALC: distance=[$distance] ship_speed=[$ship_speed] ship_capacity=[$ship_capacity]";

    my $trips_per_hour              = $distance ? ($ship_speed / $distance) : 0;
carp "RECALC: trips_per_hour=[$trips_per_hour]";
    my $max_waste_hauled_per_hour   = $trips_per_hour * $ship_capacity;
carp "RECALC: max_waste_hauled_per_hour=[$max_waste_hauled_per_hour]";
    my $waste_hauled_per_hour       = min($waste_hour, $max_waste_hauled_per_hour);
carp "RECALC: waste_hauled_per_hour=[$waste_hauled_per_hour]";
    my $shipping_capacity           = $max_waste_hauled_per_hour ? sprintf('%.0f',($waste_hour / $max_waste_hauled_per_hour) * 100) : -1;
carp "RECALC: shipping_capacity=[$shipping_capacity]";

    $waste_chains->reset;
    while (my $waste_chain = $waste_chains->next) {
        $waste_chain->percent_ship_capacity($shipping_capacity);
        $waste_chain->update;
    }

    $body->needs_recalc(1);
    $body->update;
    return $self;
}

before delete => sub {
    my ($self) = @_;
    $self->waste_ships->update({task=>'Docked'});
    $self->waste_chain->delete_all;
    $self->body->needs_recalc(1);
    $self->body->update;
};

before 'can_downgrade' => sub {
    my $self = shift;
    if ($self->waste_chains->count >= $self->level) {
        confess [1013, 'You must cancel one of your supply chains before you can downgrade the Trade Ministry.'];
    }
};

sub add_to_market {
    my ($self, $offer, $ask, $options) = @_;
    my $ship = $self->next_available_trade_ship($options->{ship_id});
    unless (defined $ship) {
        confess [1011, "You do not have any ships available that can carry trade goods."];
    }
    unless ($ask >= 0.1 && $ask < 100 ) {
        confess [1009, "You must ask for between 0.1 and 99 essentia to create a trade."];
    }
    unless ($self->level > $self->my_market->count) {
        confess [1009, "This Trade Ministry can only support ".$self->level." trades at one time."];
    }
    my $space_used = $self->check_payload($offer, $ship->hold_size, undef, $ship);
    my ($payload, $meta) = $self->structure_payload($offer, $space_used);
    $ship->task('Waiting On Trade');
    $ship->update;
    my %trade = (
        %{$meta},
        payload         => $payload,
        ask             => $ask,
        ship_id         => $ship->id,
        body_id         => $self->body_id,
        transfer_type   => $self->transfer_type,
    );
    return Lacuna->db->resultset('Lacuna::DB::Result::Market')->new(\%trade)->insert;
}

sub transfer_type {
    my $self = shift;
    return $self->body->zone;
}

sub trade_ships {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
        task    => 'Docked',
        type    => { 'in' => [qw(dory barge galleon hulk cargo_ship freighter smuggler_ship)] },
        body_id => $self->body_id,
    },
    {
        order_by=> {-desc => ['hold_size']}
    });
}

sub waste_ships {
    my ($self) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
        task    => 'Docked',
        type    => { 'in' => [qw(scow)] },
        body_id => $self->body_id,
    },
    {
        order_by=> {-desc => ['hold_size']}
    });
}

sub waste_chains {
    my ($self) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::WasteChain')->search({
        planet_id   => $self->body_id,
        star_id     => $self->body->star_id,
    },
    {
        order_by    => 'waste_hour',
    });
}

sub next_available_trade_ship {
    my ($self, $ship_id) = @_;
    if ($ship_id) {
        return $self->trade_ships->find($ship_id);
    }
    else {
        return $self->trade_ships->search(undef, {rows => 1})->single;
    }
}

sub push_items {
    my ($self, $target, $items, $options) = @_;
    my $ship = $self->next_available_trade_ship($options->{ship_id});
    unless (defined $ship) {
        confess [1011, 'You do not have a ship available to transport cargo.'];
    }

    my $space_used = $self->check_payload($items,$ship->hold_size, undef, $ship);
    $self->check_payload_ships($items,$target,$options->{stay});

    my ($payload, $meta) = $self->structure_payload($items, $space_used);
    foreach my $item (@{$items}) {
        if ( $item->{type} eq 'ship' ) {
            my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($item->{ship_id});
            next unless defined $ship;
            $ship->body_id($target->id);
            $ship->update;
        }
    }

    if ($options->{stay}) {
        $ship->body_id($target->id);
        $ship->body($target);
        $ship->send(
            target      => $self->body,
            direction   => 'in',
            payload     => $payload,
        );
    }
    else {
        $ship->send(
            target  => $target,
            payload => $payload,
        );
    }
    return $ship;
}




no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
