package Lacuna::DB::Result::Building::Food::Wheat;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

before check_build_prereqs => sub {
    my $self = shift;
    my $planet = $self->body;
    if ($planet->gypsum + $planet->sulfur + $planet->monazite < 100) {
        confess [1012,"This planet does not have a sufficient supply of phosphorus from sources like Gypsum, Sulfur, and Monazite to grow wheat."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::Wheat';

use constant min_orbit => 2;

use constant max_orbit => 4;

use constant image => 'wheat';

use constant name => 'Wheat Farm';

use constant food_to_build => 15;

use constant energy_to_build => 100;

use constant ore_to_build => 75;

use constant water_to_build => 20;

use constant waste_to_build => 10;

use constant time_to_build => 60;

use constant food_consumption => 1;

use constant wheat_production => 28;

use constant energy_consumption => 2;

use constant ore_consumption => 2;

use constant water_consumption => 2;

use constant waste_production => 8;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
