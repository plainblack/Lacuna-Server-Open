package Lacuna::DB::Result::Building::MercenariesGuild;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

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

my $have_exception = [1011, 'You cannot offer to trade something you do not have.'];
my $offer_nothing_exception = [1013, 'It appears that you have offered nothing.'];

sub market {
    return Lacuna->db->resultset('Lacuna::DB::Result::MercenaryMarket');
}

sub my_market { 
    my $self = shift;
    return $self->market->search({body_id => $self->body_id });
}

sub available_market {
    my $self = shift;
    return $self->market->search(
        {
            body_id         => {'!=' => $self->body_id},
        },
    )
}

sub add_to_market {
    my ($self, $cost, $spy_id, $ask, $ship_id) = @_;
    confess $offer_nothing_exception unless $spy_id;
    unless ($ask >= 0.1 && $ask < 100 ) {
        confess [1009, "You must ask for between 0.1 and 99 essentia to create a trade."];
    }
    my $ship = $self->next_available_trade_ship($ship_id);
    unless (defined $ship) {
        confess [1011, "You do not have any spy pods available."];
    }
    unless ($self->level > $self->my_market->count) {
        confess [1009, "This Mercenaries Guild can only support ".$self->level." spies at one time."];
    }
    my $spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($spy_id);
    confess $have_exception unless (defined $spy && $self->body_id eq $spy->on_body_id && $spy->task ~~ ['Counter Espionage','Idle']);
    $spy->task('Mercenary Transport');
    $spy->update;
    $ship->task('Waiting On Trade');
    $ship->update;
    my $payload = { mercenary => $spy->id };
    my %trade = (
        body_id         => $self->body_id,
        ship_id         => $ship->id,
        ask             => $ask,
        cost            => $cost,
        payload         => $payload,
    );
    return Lacuna->db->resultset('Lacuna::DB::Result::MercenaryMarket')->new(\%trade)->insert;
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

sub next_available_trade_ship {
    my ($self, $ship_id) = @_;
    if ($ship_id) {
        return $self->trade_ships->find($ship_id);
    }
    else {
        return $self->trade_ships->search(undef, {rows => 1})->single;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
