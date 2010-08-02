package Lacuna::DB::Result::Building::Energy::Fusion;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Energy';

before check_build_prereqs => sub {
    my $self = shift;
    my $planet = $self->body;
    if ($planet->galena + $planet->halite < 500) {
        confess [1012,"This planet does not have a sufficient supply of coolants such as Galena and Halite to operate this reactor."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::Fusion';

use constant university_prereq => 9;

use constant image => 'fusion';

use constant name => 'Fusion Reactor';

use constant food_to_build => 270;

use constant energy_to_build => 340;

use constant ore_to_build => 320;

use constant water_to_build => 240;

use constant waste_to_build => 300;

use constant time_to_build => 175;

use constant food_consumption => 1;

use constant energy_consumption => 12;

use constant energy_production => 143;

use constant ore_consumption => 7;

use constant water_consumption => 15;

use constant waste_production => 2;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
