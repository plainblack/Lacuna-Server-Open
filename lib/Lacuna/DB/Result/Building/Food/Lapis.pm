package Lacuna::DB::Result::Building::Food::Lapis;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

before check_build_prereqs => sub {
    my $self = shift;
    my $planet = $self->body;
    if ($planet->gypsum + $planet->sulfur + $planet->monazite < 100) {
        confess [1012,"This planet does not have a sufficient supply of phosphorus from sources like Gypsum, Sulfur, and Monazite to grow lapis trees."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::Lapis';

use constant min_orbit => 2;

use constant max_orbit => 2;

use constant image => 'lapis';

use constant name => 'Lapis Orchard';

use constant food_to_build => 15;

use constant energy_to_build => 71;

use constant ore_to_build => 75;

use constant water_to_build => 140;

use constant waste_to_build => 5;

use constant time_to_build => 65;

use constant food_consumption => 1;

use constant lapis_production => 44;

use constant energy_consumption => 2;

use constant ore_consumption => 5;

use constant water_consumption => 5;

use constant waste_production => 13;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
