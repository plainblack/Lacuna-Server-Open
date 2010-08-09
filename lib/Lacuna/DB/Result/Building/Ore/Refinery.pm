package Lacuna::DB::Result::Building::Ore::Refinery;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Ore';

before check_build_prereqs => sub {
    my $self = shift;
    my $planet = $self->body;
    if ($planet->sulfur + $planet->fluorite < 500) {
        confess [1012,"This planet does not have a sufficient supply (500) of processing minerals such as Sulfur and Fluorite to refine ore."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::OreRefinery';

use constant building_prereq => {'Lacuna::DB::Result::Building::Ore::Mine' => 5};

use constant max_instances_per_planet => 1;

use constant image => 'orerefinery';

use constant name => 'Ore Refinery';

use constant food_to_build => 147;

use constant energy_to_build => 148;

use constant ore_to_build => 147;

use constant water_to_build => 148;

use constant waste_to_build => 100;

use constant time_to_build => 125;

use constant food_consumption => 5;

use constant energy_consumption => 30;

use constant water_consumption => 14;

use constant waste_production => 16;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
