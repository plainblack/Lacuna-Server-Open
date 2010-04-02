package Lacuna::DB::Building::Ore::Platform;

use Moose;
extends 'Lacuna::DB::Building::Ore';

use constant controller_class => 'Lacuna::Building::MiningPlatform';

sub check_build_prereqs {
    confess [1013,"You can't directly build a Mining Platform. You need a mining platform ship."];
}

use constant image => 'miningplatform';

use constant name => 'Mining Platform';



no Moose;
__PACKAGE__->meta->make_immutable;

