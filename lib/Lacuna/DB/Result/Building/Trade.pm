package Lacuna::DB::Result::Building::Trade;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

with 'Lacuna::Role::Trader';

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
    if ($options->{stay}) {
        my $spaceport = $target->spaceport;
        if (defined $spaceport) {
            unless ($spaceport->docks_available) {
                confess [1011, 'There are no available docks on the remote planet.'];
            }
        }
        else {
            confess [1011, 'You cannot have the ship stay on the remote planet unless there is a Space Port there.'];
        }
    }
    
    my $space_used = $self->check_payload($items, $ship->hold_size, undef, $ship);
    my $ship_count = 0;
    foreach my $item (@{$items}) {
        $ship_count++ if $item->{type} eq 'ship';
    }
    $ship_count++ if ($options->{stay});
    if ($ship_count) {
        my $spaceport = $target->spaceport;
        if (defined $spaceport) {
            unless ($spaceport->docks_available >= $ship_count) {
                confess [1011, 'There are no available docks on the remote planet.'];
            }
        }
        else {
            confess [1011, 'You cannot push ships to a planet that does not have a space port.'];
        }
    }

    my ($payload, $meta) = $self->structure_payload($items, $space_used);
    foreach my $item (@{$items}) {
        if ( $item->{type} eq 'ship' ) {
            my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($item->{ship_id});
            next unless defined $ship;
            $ship->body_id($body->id);
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
    #my $cargo_log = Lacuna->db->resultset('Lacuna::DB::Result::Log::Cargo');
    #$cargo_log->new({
    #    message     => 'push resources',
    #    body_id     => $ship->foreign_body_id,
    #    data        => $ship->payload,
    #    object_type => ref($ship),
    #    object_id   => $ship->id,
    #})->insert;
    return $ship;
}




no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
