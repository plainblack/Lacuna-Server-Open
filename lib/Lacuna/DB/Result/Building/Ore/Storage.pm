package Lacuna::DB::Result::Building::Ore::Storage;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Ore';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Storage));
};

use constant controller_class => 'Lacuna::RPC::Building::OreStorage';

use constant image => 'orestorage';

use constant name => 'Ore Storage Tanks';

use constant food_to_build => 10;

use constant energy_to_build => 10;

use constant ore_to_build => 10;

use constant water_to_build => 10;

use constant waste_to_build => 25;

use constant time_to_build => 30;

use constant ore_storage => 1000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
