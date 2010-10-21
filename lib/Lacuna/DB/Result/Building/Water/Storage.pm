package Lacuna::DB::Result::Building::Water::Storage;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Water';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Storage));
};

use constant controller_class => 'Lacuna::RPC::Building::WaterStorage';

use constant image => 'waterstorage';

use constant name => 'Water Storage Tank';

use constant food_to_build => 35;

use constant energy_to_build => 35;

use constant ore_to_build => 35;

use constant water_to_build => 35;

use constant waste_to_build => 35;

use constant time_to_build => 63;

use constant food_consumption => 1;

use constant energy_consumption => 1;

use constant ore_consumption => 1;

use constant water_consumption => 1;

use constant water_storage => 1000;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
