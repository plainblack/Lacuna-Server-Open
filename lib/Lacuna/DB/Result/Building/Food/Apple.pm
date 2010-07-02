package Lacuna::DB::Result::Building::Food::Apple;

use Moose;
extends 'Lacuna::DB::Result::Building::Food';

before check_build_prereqs => sub {
    my $self = shift;
    my $planet = $self->body;
    if ($planet->gypsum + $planet->sulfur + $planet->monazite < 100) {
        confess [1012,"This planet does not have a sufficient supply of phosphorus from sources like Gypsum, Sulfur, and Monazite to grow apple trees."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::Apple';

use constant min_orbit => 3;

use constant max_orbit => 3;

use constant image => 'apples';

use constant name => 'Apple Orchard';

use constant food_to_build => 25;

use constant energy_to_build => 50;

use constant ore_to_build => 55;

use constant water_to_build => 175;

use constant waste_to_build => 5;

use constant time_to_build => 65;

use constant food_consumption => 1;

use constant apple_production => 43;

use constant energy_consumption => 2;

use constant ore_consumption => 2;

use constant water_consumption => 5;

use constant waste_production => 8;

use constant waste_consumption => 1;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
