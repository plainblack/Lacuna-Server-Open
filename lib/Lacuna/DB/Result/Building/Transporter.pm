package Lacuna::DB::Result::Building::Transporter;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);

with 'Lacuna::Role::Trader','Lacuna::Role::Fleet::Trade';


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
use constant max_instances_per_planet => 1;

use constant waste_production => 1;



sub add_to_market {
    my ($self, $offer, $ask, $internal_options) = @_;
    $ask = sprintf("%0.1f", $ask);
    unless(Lacuna::Role::Trader::OVERLOAD_ALLOWED()) {
        unless ($ask >= 0.1 && $ask <= 100 ) {
            confess [1009, "You must ask for between 0.1 and 100 essentia to create a trade."];
        }
        unless ($self->effective_level > $self->my_market->count) {
            confess [1009, "This Subspace Transporter can only support ".$self->effective_level." trades at one time."];
        }
    }
    my $space_used;
    ($space_used, $offer) = $self->check_payload($offer, $self->determine_available_cargo_space);
    my ($payload, $meta) = $self->structure_payload($offer, $space_used);
    my %trade = (
        %{$meta},
        payload         => $payload,
        ask             => $ask,
        body_id         => $self->body_id,
        transfer_type   => $self->transfer_type,
    );
    $trade{max_university} = $internal_options->{max_university} if $internal_options;
    return Lacuna->db->resultset('Lacuna::DB::Result::Market')->new(\%trade)->insert;
}

sub transfer_type {
    return 'transporter';
}

sub available_market {
    my $self = shift;
    return $self->market->search(
        {
            body_id         => {'!=' => $self->body_id},
            transfer_type   => $self->transfer_type,
        },
    )
}

sub determine_available_cargo_space {
    my ($self) = @_;
    return 12500 * $self->effective_level * $self->body->empire->effective_trade_affinity;
}

sub trade_one_for_one {
    my ($self, $have, $want, $quantity) = @_;
    unless ($quantity > 0) {
        confess [1011, 'You cannot trade negative amounts of something.'];
    }
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
    $body->can_add_type($want, $quantity);
    $empire->spend_essentia({
        amount  => 3, 
        reason  => 'Lacunans Trade',
    });
    $empire->update;
    $body->spend_type($have, $quantity);
    $body->add_type($want, $quantity);
    $body->update;
}

sub push_items {
    my ($self, $target, $transporter, $items) = @_;
    my $local_payload = $self->determine_available_cargo_space;
    my $remote_payload = $transporter->determine_available_cargo_space;
    my $space_available = $local_payload;
    my $space_exception = 'You are trying to send %s cargo, but the local transporter can only send '.$local_payload.'.';
    if ($remote_payload < $local_payload) {
        $space_available = $remote_payload;
        $space_exception = 'You are trying to send %s cargo, but the remote transporter can only receive '.$remote_payload.'.';
    }

    my $space_used;
    ($space_used, $items) = $self->check_payload($items, $local_payload);
    $space_used = $self->check_payload_ships($items, $target);

    my ($payload, $meta) = $self->structure_payload($items, $space_used);
    my $container = Lacuna::VirtualContainer->new(payload => $payload);
    $container->unload($target);
}

before delete => sub {
  my ($self) = @_;
    
  my $market = Lacuna->db->resultset('Lacuna::DB::Result::Market');
  my @to_be_deleted = $market->search( { body_id => $self->body_id,
                                         transfer_type => 'transporter'} )->get_column('id')->all;
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
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
