package Lacuna::DB::Building::Food::Factory::Burger;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

use constant controller_class => 'Lacuna::Building::Burger';

use constant image => 'burger';

use constant building_prereq => {'Lacuna::DB::Building::Food::Farm::Malcud'=>5};

use constant name => 'Malcud Burger Packer';

use constant food_to_build => 135;

use constant energy_to_build => 135;

use constant ore_to_build => 135;

use constant water_to_build => 135;

use constant waste_to_build => 100;

use constant time_to_build => 200;

use constant food_consumption => 30;

use constant burger_production => 30;

use constant energy_consumption => 8;

use constant ore_consumption => 4;

use constant water_consumption => 2;

use constant waste_production => 14;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
