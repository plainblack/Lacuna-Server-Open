package Lacuna::DB::Building::Ore::Storage;

use Moose;
extends 'Lacuna::DB::Building::Ore';

use constant controller_class => 'Lacuna::Building::OreStorage';

use constant image => 'orestorage';

use constant name => 'Ore Storage Tanks';

use constant food_to_build => 10;

use constant energy_to_build => 10;

use constant ore_to_build => 10;

use constant water_to_build => 10;

use constant waste_to_build => 25;

use constant time_to_build => 300;

use constant ore_storage => 1500;


no Moose;
__PACKAGE__->meta->make_immutable;
