package Lacuna::DB::Result::Building::Trade;

use Moose;
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


sub add_trade {
    my ($self, $offer, $ask) = @_;
    my $ship = $self->next_available_trade_ship;
    unless (defined $ship) {
        confess [1011, "You do not have any ships available that can carry trade goods."];
    }
    $ask = $self->structure_ask($ask);
    $offer = $self->structure_offer($offer, $ship->hold_size);
    $ship->task('Waiting On Trade');
    $ship->update;
    my %trade = (
        %{$ask},
        %{$offer},
        ship_id         => $ship->id,
        body_id         => $self->body_id,
        transfer_type   => $self->transfer_type,
    );
    return Lacuna->db->resultset('Lacuna::DB::Result::Trades')->new(\%trade)->insert;
}


sub transfer_type {
    my $self = shift;
    return $self->body->zone;
}

sub trade_ships {
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships');
}

sub next_available_trade_ship {
    my $self = shift;
    return $self->trade_ships
        ->search({
            task    => 'Docked',
            hold_size   => { '>', 0 },
            body_id => $self->body_id,
        }, {
            rows    => 1,
            order_by=> {-desc => ['hold_size']}
        })->single;
}

sub push_items {
    my ($self, $target, $items) = @_;
    my $ship = $self->next_available_trade_ship;
    unless (defined $ship) {
        confess [1011, 'You do not have a ship available to transport cargo.'];
    }
    my $payload = $self->structure_push($items, $ship->hold_size);
    $ship->send(
        target  => $target,
        payload => $payload,
    );
    return $ship;
}




no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
