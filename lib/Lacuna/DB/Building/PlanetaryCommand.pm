package Lacuna::DB::Building::PlanetaryCommand;

use Moose;
extends 'Lacuna::DB::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Resources Ore Water Waste Energy Food Colonization));
};

use constant controller_class => 'Lacuna::Building::PlanetaryCommand';

sub check_build_prereqs {
    confess [1013,"You can't directly build a Planetary Command. You need a colony ship."];
}

use constant image => 'command';

use constant name => 'Planetary Command Center';

use constant food_to_build => 320;

use constant energy_to_build => 320;

use constant ore_to_build => 320;

use constant water_to_build => 320;

use constant waste_to_build => 500;

use constant time_to_build => 600;

use constant algae_production => 20;

use constant energy_production => 20;

use constant ore_production => 20;

use constant water_production => 20;

use constant waste_production => 2;

use constant food_storage => 525;

use constant energy_storage => 525;

use constant ore_storage => 525;

use constant water_storage => 525;

use constant waste_storage => 100;



no Moose;
__PACKAGE__->meta->make_immutable;
