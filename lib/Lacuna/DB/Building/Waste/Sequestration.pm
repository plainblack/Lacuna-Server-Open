package Lacuna::DB::Building::Waste::Sequestration;

use Moose;
extends 'Lacuna::DB::Building::Waste';

use constant controller_class => 'Lacuna::Building::WasteSequestration';

use constant image => 'wastesequestration';

use constant name => 'Waste Sequestration Well';

use constant university_prereq => 3;

use constant food_to_build => 10;

use constant energy_to_build => 10;

use constant ore_to_build => 10;

use constant water_to_build => 10;

use constant waste_to_build => 25;

use constant time_to_build => 90;

use constant waste_storage => 1000;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
