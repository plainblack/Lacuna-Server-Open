package Lacuna::DB::Result::Building::MercenariesGuild;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Trade';

with 'Lacuna::Role::SpyTrader';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Intelligence Ships Trade));
};

use constant controller_class => 'Lacuna::RPC::Building::MercenariesGuild';

use constant university_prereq => 10;

use constant image => 'mercenariesguild';

use constant name => 'Mercenaries Guild';

use constant food_to_build => 700;

use constant energy_to_build => 800;

use constant ore_to_build => 900;

use constant water_to_build => 700;

use constant waste_to_build => 700;

use constant time_to_build => 600;

use constant food_consumption => 5;

use constant energy_consumption => 28;

use constant ore_consumption => 3;

use constant water_consumption => 5;

use constant waste_production => 1;

use constant max_instances_per_planet => 1;

sub add_to_market {
    my ($self, $offer, $ask, $options) = @_;
    my $ship = $self->next_available_trade_ship($options->{ship_id});
    unless (defined $ship) {
        confess [1011, "You do not have any spy pods available."];
    }
    unless ($ask >= 0.1 && $ask < 100 ) {
        confess [1009, "You must ask for between 0.1 and 99 essentia to create a trade."];
    }
    unless ($self->level > $self->my_market->count) {
        confess [1009, "This Mercenaries Guild can only support ".$self->level." spies at one time."];
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

sub trade_ships {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
        task    => 'Docked',
        type    => 'spy_pod',
        body_id => $self->body_id,
    },
    {
        order_by=> {-desc => ['name']}
    });
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
