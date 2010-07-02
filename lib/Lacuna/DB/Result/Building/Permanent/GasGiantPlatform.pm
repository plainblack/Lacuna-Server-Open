package Lacuna::DB::Result::Building::Permanent::GasGiantPlatform;

use Moose;
extends 'Lacuna::DB::Result::Building::Permanent';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Colonization));
};

use constant controller_class => 'Lacuna::RPC::Building::GasGiantPlatform';

use constant image => 'gas-giant-platform';

sub check_build_prereqs {
    my ($self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return 1;  
    }
    confess [1013,"You can't directly build a Gas Giant Platform. You need a gas giant platform ship."];
}

use constant name => 'Gas Giant Settlement Platform';

use constant food_to_build => 1500;

use constant energy_to_build => 1500;

use constant ore_to_build => 1500;

use constant water_to_build => 1500;

use constant waste_to_build => 1500;

use constant time_to_build => 300;

use constant waste_production => 30;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
