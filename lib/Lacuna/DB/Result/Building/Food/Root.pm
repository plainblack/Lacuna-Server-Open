package Lacuna::DB::Result::Building::Food::Root;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

before can_build => sub {
    my $self = shift;
    my $planet = $self->body;
    if ($planet->gypsum + $planet->sulfur + $planet->monazite < 100) {
        confess [1012,"This planet does not have a sufficient supply (100) of phosphorus from sources like Gypsum, Sulfur, and Monazite to grow denton roots."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::Denton';

use constant min_orbit => 5;

use constant max_orbit => 6;

use constant image => 'roots';

use constant name => 'Denton Root Patch';

use constant food_to_build => 10;

use constant energy_to_build => 100;

use constant ore_to_build => 52;

use constant water_to_build => 10;

use constant waste_to_build => 10;

use constant time_to_build => 60;

use constant food_consumption => 1;

use constant root_production => 25;

use constant energy_consumption => 1;

use constant ore_consumption => 1;

use constant water_consumption => 2;

use constant waste_production => 1;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
