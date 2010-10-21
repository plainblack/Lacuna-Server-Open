package Lacuna::DB::Result::Building::Food::Corn;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

before has_special_resources => sub {
    my $self = shift;
    my $planet = $self->body;
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.01);
    if ($planet->gypsum_stored + $planet->sulfur_stored + $planet->monazite_stored < $amount_needed) {
        confess [1012,"You do not have a sufficient supply (".$amount_needed.") of phosphorus from sources like Gypsum, Sulfur, and Monazite to grow plants."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::Corn';

use constant min_orbit => 2;

use constant max_orbit => 3;

use constant image => 'corn';

use constant name => 'Corn Plantation';

use constant food_to_build => 10;

use constant energy_to_build => 70;

use constant ore_to_build => 55;

use constant water_to_build => 83;

use constant waste_to_build => 10;

use constant time_to_build => 60;

use constant food_consumption => 1;

use constant corn_production => 28;

use constant energy_consumption => 1;

use constant ore_consumption => 2;

use constant water_consumption => 2;

use constant waste_production => 5;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(corn);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
