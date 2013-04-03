package Lacuna::DB::Result::Building::Trade;

use Moose;
use List::Util qw(max min);
use Carp;
use Scalar::Util qw(weaken);

use utf8;
use List::Util qw(max);
use Data::Dumper;
use Lacuna::Constants qw(SHIP_TRADE_TYPES SHIP_WASTE_TYPES);

no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

with 'Lacuna::Role::Trader','Lacuna::Role::Fleet::Trade';

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

sub supply_chains {
    my ($self) = @_;

    return Lacuna->db->resultset('SupplyChain')->search({ planet_id => $self->body_id });
}

    
sub waste_chains {
    my $self = shift;

    # If there is no waste chain, then create a default one
    my $waste_chain = Lacuna->db->resultset('WasteChain')->search({ planet_id => $self->body_id });
    if ($waste_chain->count == 0) {
        Lacuna->db->resultset('WasteChain')->create({
            planet_id   => $self->body_id,
            star_id     => $self->body->star_id,
            waste_hour  => 0,
            percent_transferred => 0,
        });
    }
    return Lacuna->db->resultset('WasteChain')->search({ planet_id => $self->body_id });
}

# Fleets that are currently in a supply chain
sub supply_fleets {
    my ($self) = @_;

    return Lacuna->db->resultset('Fleet')->search({
        body_id     => $self->body_id,
        task        => 'Supply Chain',
    });
}

# Fleets that are currently in a waste chain
sub waste_fleetss {
    my ($self) = @_;

    return Lacuna->db->resultset('Fleet')->search({
        body_id     => $self->body_id,
        task        => 'Waste Chain',
    });
}

# All fleets that are either in a supply chain, or available to be so
sub all_supply_fleets {
    my ($self) = @_;

    return Lacuna->db->resultset('Fleet')->search({
        body_id => $self->body_id,
        -or => {
            task => 'Supply Chain',
            -and => [
                task => 'Docked',
                berth_level => {'<=' => $self->body->max_berth},
                type => { '=', [SHIP_TRADE_TYPES]},
            ]
        }
    },{
        order_by => {-desc => [qw(task hold_size)]},
    });
}

# All fleets that are either in a waste chain, or available to be so
sub all_waste_fleets {
    my ($self) = @_;

    return Lacuna->db->resultset('Fleet')->search({
        body_id => $self->body_id,
        -or => { 
            task => 'Waste Chain',
            -and => [
                task => 'Docked',
                berth_level => {'<=' => $self->body->max_berth},
                type => { '=', [SHIP_WASTE_TYPES]},
            ]
        }
    },{
        order_by => {-desc => [qw(task hold_size)]},
    });
}

sub max_chains {
    my ($self) = @_;

    return ceil($self->effective_level);
}

sub add_fleet_to_waste_duty {
    my ($self, $fleet) = @_;
    
    $fleet->task('Waste Chain');
    $fleet->update;
    $self->recalc_waste_production;
    return $self;
}

sub add_fleet_to_supply_duty {
    my ($self, $fleet) = @_;

    $fleet->task('Supply Chain');
    $fleet->update;
    $self->recalc_supply_production;
    return $self;
}

sub remove_waste_fleet {
    my ($self, $star, $ship) = @_;
    $ship->send(
        target      => $star,
        direction   => 'in',
        task        => 'Travelling',
        emptyscow   => 1,
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
    Lacuna->db->resultset('WasteChain')->new({
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

sub remove_supply_chain {
    my ($self, $supply_chain) = @_;
    if ($self->supply_chains->count == 1) {
        my $ships = $self->supply_ships;
        while (my $ship = $ships->next) {
            $self->send_supply_ship_home($supply_chain->target, $ship);
        }
    }
    my $target = $supply_chain->target;
    $supply_chain->delete;
    $self->recalc_supply_production;
    $target->needs_recalc(1);
    $target->update;
    return $self;
}

sub recalc_supply_production {
    my ($self) = @_;
    my $body = $self->body;

    # Determine the resource/hour/distance for the ship
    my $ship_rphpd = 0;
    my $ships = $self->supply_ships;
    while (my $ship = $ships->next) {
        $ship_rphpd += $ship->hold_size * $ship->speed;
    }
    # Determine the resource/hour for supply chains
    my $chain_rphpd = 0;
    my $supply_chains   = $self->supply_chains->search({},{prefetch => 'target'});
    while (my $supply_chain = $supply_chains->next) {
        $chain_rphpd += $body->calculate_distance_to_target($supply_chain->target) * 2 * $supply_chain->resource_hour;
    }
    my $shipping_capacity = $chain_rphpd ? sprintf('%.0f',($ship_rphpd / $chain_rphpd) * 100) : 0;

    $supply_chains->reset;
    while (my $supply_chain = $supply_chains->next) {
        $supply_chain->percent_transferred($shipping_capacity);
        $supply_chain->update;
        my $target = $supply_chain->target;
        $target->needs_recalc(1);
        $target->update;
    }

    $body->needs_recalc(1);
    $body->update;

    return $self;
}
    

sub recalc_waste_production {
    my ($self) = @_;
    my $body = $self->body;

    # Determine the waste/hour/distance for ship
    my $ship_wphpd = 0;
    my $ships = $self->waste_ships;
    while (my $ship = $ships->next) {
        $ship_wphpd += $ship->hold_size * $ship->speed;
    }

    # Determine the waste/hour for waste chains
    my $chain_wphpd         = 0;
    my $waste_chains        = $self->waste_chains;
    while (my $waste_chain = $waste_chains->next) {
        $chain_wphpd += $body->calculate_distance_to_target($waste_chain->star) * 2 * $waste_chain->waste_hour;
    }
    my $shipping_capacity = $chain_wphpd ? int(100 * $ship_wphpd / $chain_wphpd) : 0;

    $waste_chains->reset;
    while (my $waste_chain = $waste_chains->next) {
        $waste_chain->percent_transferred($shipping_capacity);
        $waste_chain->update;
    }

    $body->needs_recalc(1);
    $body->update;
    return $self;
}

before delete => sub {
    my ($self) = @_;
    
    my $market = Lacuna->db->resultset('Market');
    my @to_be_deleted = $market->search( { body_id => $self->body_id,
                                         transfer_type => 'trade'} )->get_column('id')->all;
    foreach my $id (@to_be_deleted) {
        my $trade = $market->find($id);
        next unless defined $trade;
        $trade->body->empire->send_predefined_message(
            filename    => 'trade_withdrawn.txt',
            params      => [join("\n",@{$trade->format_description_of_payload}), $trade->ask.' essentia'],
            tags        => ['Trade','Alert'],
        );
        $trade->withdraw;
    }
    $self->waste_ships->update({task=>'Docked'});
    $self->waste_chains->delete_all;
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
    my ($self, $offer, $ask, $fleet_id, $internal_options) = @_;
    my $ship = $self->next_available_trade_ship($fleet_id);
    unless (defined $ship) {
        confess [1011, "You do not have any ships available that can carry trade goods."];
    }
    unless(Lacuna::Role::Trader::OVERLOAD_ALLOWED()) {
        $ask = sprintf("%0.1f", $ask);
        unless ($ask >= 0.1 && $ask <= 100 ) {
            confess [1009, "You must ask for between 0.1 and 100 essentia to create a trade."];
        }
        unless ($self->effective_level > $self->my_market->count) {
            confess [1009, "This Trade Ministry can only support ".$self->effective_level." trades at one time."];
        }
    }
    my $space_used;
    ($space_used, $offer ) = $self->check_payload($offer, $ship->hold_size, undef, $ship);
    my ($payload, $meta) = $self->structure_payload($offer, $space_used);
    $ship->task('Waiting On Trade');
    $ship->update;
    my $body = $self->body;
    my %trade = (
        %{$meta},
        payload         => $payload,
        ask             => $ask,
        ship_id         => $ship->id,
        body_id         => $self->body_id,
        transfer_type   => $self->transfer_type,
        x               => $body->x,
        y               => $body->y,
        speed           => $ship->speed,
        trade_range     => int(450 + (15 * $self->effective_level)),
    );
    $trade{max_university} = $internal_options->{max_university} if $internal_options;
    return Lacuna->db->resultset('Market')->new(\%trade)->insert;
}

sub transfer_type {
    my $self = shift;
    return 'trade';
}

# all trades within range (including those on this colony)
sub local_market {
    my ($self, $args) = @_;

    my $minus_x = -$self->body->x;
    my $minus_y = -$self->body->y;

    return $self->market->search({
        %$args,
        -and => [
            \[ "transfer_type = ? and ceil(pow(pow(me.x + $minus_x, 2) + pow(me.y + $minus_y, 2), 0.5)) < trade_range", [transfer_type => $self->transfer_type]],
        ]
    },{
        '+select' => [
            { ceil => \"pow(pow(me.x + $minus_x,2) + pow(me.y + $minus_y,2), 0.5)", '-as' => 'distance' },
        ],
        '+as' => [
            'distance',
        ],
        join => 'body',
    });
}

# available market. All trades within range that are not our own
sub available_market {
    my ($self) = @_;
    return $self->local_market({
        body_id => {'!=' => $self->body_id},
    });
}

# TODO Order by hold_size * quantity
# 
sub trade_fleets {
    my ($self) = @_;

    my $body = $self->body;
    return Lacuna->db->resultset('Fleet')->search({
        task    => 'Docked',
        type    => { 'in' => [SHIP_TRADE_TYPES] },
        body_id => $self->body_id,
        berth_level => {'<=' => $body->max_berth }
    },
    {
        order_by=> {-desc => ['hold_size']}
    });
}

sub next_available_trade_fleet {
    my ($self, $fleet_id) = @_;
    if ($fleet_id) {
        return $self->trade_fleets->find($fleet_id);
    }
    else {
        return $self->trade_fleets->search(undef, {rows => 1})->single;
    }
}

sub push_items {
    my ($self, $target, $items, $fleet_options) = @_;

    my $fleet = $self->next_available_trade_fleet($fleet_options->{id});

    unless (defined $fleet) {
        confess [1011, 'You do not have a fleet available to transport cargo.'];
    }

    my $space_used;
    ($space_used, $items) = $self->check_payload($items, $fleet->hold_size, undef, $fleet);
    $self->check_payload_fleet_size($items, $target, $fleet_options->{stay});

    my ($payload, $meta) = $self->structure_payload($items, $space_used);
    foreach my $item (@{$items}) {
        if ( $item->{type} eq 'fleet' ) {
            my $push_fleet = Lacuna->db->resultset('Fleet')->find($item->{fleet_id});
            next unless defined $push_fleet;
            $push_fleet->body_id($target->id);
            $push_fleet->update;
        }
    }

    if ($fleet_options->{stay}) {
        $fleet->body_id($target->id);
        $fleet->body($target);
        weaken($fleet->{_relationship_data}{body});
        $fleet->send(
            target      => $self->body,
            direction   => 'in',
            payload     => $payload,
        );
    }
    else {
        $fleet->send(
            target  => $target,
            payload => $payload,
        );
    }
    return $fleet;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

