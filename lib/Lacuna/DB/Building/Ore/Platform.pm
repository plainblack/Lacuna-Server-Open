package Lacuna::DB::Building::Ore::Platform;

use Moose;
extends 'Lacuna::DB::Building::Ore';

use constant controller_class => 'Lacuna::Building::MiningPlatform';

sub check_build_prereqs {
    confess [1013,"You can't directly build a Mining Platform. You need a mining platform ship."];
}

use constant image => 'miningplatform';

use constant name => 'Mining Platform';

use constant food_to_build => 500;

use constant energy_to_build => 500;

use constant ore_to_build => 50;

use constant water_to_build => 500;

use constant waste_to_build => 425;

use constant time_to_build => 5000;

use constant food_consumption => 10;

use constant energy_consumption => 50;

use constant ore_production => 280;

use constant water_consumption => 50;

use constant waste_production => 50;


no Moose;
__PACKAGE__->meta->make_immutable;

