package Lacuna::DB::Building::Permanent::GasGiantPlatform;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Colonization));
};

use constant controller_class => 'Lacuna::Building::GasGiantPlatform';

use constant image => 'gas-giant-platform';

sub check_build_prereqs {
    confess [1013,"You can't directly build a Gas Giant Platform. You need a gas giant platform ship."];
}

use constant name => 'Gas Giant Settlement Platform';

use constant food_to_build => 1500;

use constant energy_to_build => 1500;

use constant ore_to_build => 1500;

use constant water_to_build => 1500;

use constant waste_to_build => 1500;

use constant time_to_build => 600;

use constant waste_production => 150;

no Moose;
__PACKAGE__->meta->make_immutable;
