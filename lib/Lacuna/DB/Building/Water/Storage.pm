package Lacuna::DB::Building::Water::Storage;

use Moose;
extends 'Lacuna::DB::Building::Water';

use constant controller_class => 'Lacuna::Building::WaterStorage';

use constant image => 'waterstorage';

use constant name => 'Water Storage Tank';

use constant food_to_build => 35;

use constant energy_to_build => 35;

use constant ore_to_build => 35;

use constant water_to_build => 35;

use constant waste_to_build => 35;

use constant time_to_build => 125;

use constant food_consumption => 2;

use constant energy_consumption => 5;

use constant ore_consumption => 5;

use constant water_consumption => 1;

use constant waste_production => 1;

use constant water_storage => 1500;



no Moose;
__PACKAGE__->meta->make_immutable;
