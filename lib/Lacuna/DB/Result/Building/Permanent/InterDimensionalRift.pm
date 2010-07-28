package Lacuna::DB::Result::Building::Permanent::InterDimensionalRift;

use Moose;
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::InterDimensionalRift';

sub check_build_prereqs {
    my ($self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return 1;  
    }
    confess [1013,"You can't build an Interdimensional Rift. It was left behind by the Great Race."];
}

sub can_upgrade {
    confess [1013, "You can't upgrade an Interdimensional Rift. It was left behind by the Great Race."];
}

use constant image => 'interdimensionalrift';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Interdimensional Rift';

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;
use constant energy_storage => 200_000;
use constant water_storage => 200_000;
use constant food_storage => 200_000;
use constant ore_storage => 200_000;
use constant waste_storage => 200_000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
