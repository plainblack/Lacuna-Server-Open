package Lacuna::DB::Result::Building::Transporter;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);

with 'Lacuna::Role::Trader';
with 'Lacuna::Role::Container';


around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Trade));
};

use constant controller_class => 'Lacuna::RPC::Building::Transporter';

use constant university_prereq => 10;

use constant image => 'transporter';

use constant name => 'Subspace Transporter';

use constant food_to_build => 700;

use constant energy_to_build => 800;

use constant ore_to_build => 900;

use constant water_to_build => 700;

use constant waste_to_build => 700;

use constant time_to_build => 600;

use constant food_consumption => 5;

use constant energy_consumption => 10;

use constant ore_consumption => 3;

use constant water_consumption => 5;

use constant waste_production => 1;

sub add_trade {
    my ($self, $offer, $ask) = @_;
    $ask = $self->structure_ask($ask);
    $offer = $self->structure_offer($offer, $self->determine_available_cargo_space);
    my %trade = (
        %{$ask},
        %{$offer},
        body_id         => $self->body_id,
        transfer_type   => $self->transfer_type,
    );
    return Lacuna->db->resultset('Lacuna::DB::Result::Trades')->new(\%trade)->insert;
}

sub transfer_type {
    return 'transporter';
}

sub determine_available_cargo_space {
    my ($self) = @_;
    return 2000 * $self->level * $self->body->empire->species->trade_affinity;
}

sub trade_one_for_one {
    my ($self, $have, $want, $quantity) = @_;
    unless ($self->determine_available_cargo_space >= $quantity) {
        confess [1011, 'This transporter has a maximum load size of '.$self->determine_available_cargo_space.'.'];
    }
    my @types = (FOOD_TYPES, ORE_TYPES, qw(water waste energy));
    unless ($have ~~ \@types) {
        confess [1009, 'There is no resource called '.$have.'.'];
    }
    unless ($want ~~ \@types) {
        confess [1009, 'There is no resource called '.$want.'.'];
    }
    my $body = $self->body;
    unless ($body->type_stored($have) >= $quantity) {
        confess [1011, 'There is not enough '.$have.' in storage to trade.'];
    }
    my $empire = $body->empire;
    unless ($empire->essentia >= 3) {
        confess [1011, 'You need 3 essentia to conduct this trade.'];
    }
    $empire->spend_essentia(3, 'Lacunans Trade')->update;
    $body->spend_type($have, $quantity);
    $body->add_type($want, $quantity);
    $body->update;
}

sub push_items {
    my ($self, $target, $transporter, $items) = @_;
    my $local_payload = $self->determine_available_cargo_space;
    my $remote_payload = $transporter->determine_available_cargo_space;
    my $space_available = ($remote_payload < $local_payload) ? $remote_payload : $local_payload;
    my $payload = $self->structure_push($items, $space_available);
    $self->unload($payload, $target);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
