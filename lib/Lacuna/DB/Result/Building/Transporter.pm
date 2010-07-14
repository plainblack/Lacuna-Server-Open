package Lacuna::DB::Result::Building::Transporter;

use Moose;
extends 'Lacuna::DB::Result::Building';

with 'Lacuna::Role::Trader';


around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
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

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
