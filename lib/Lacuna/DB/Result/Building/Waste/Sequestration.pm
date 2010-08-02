package Lacuna::DB::Result::Building::Waste::Sequestration;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Waste';

use constant controller_class => 'Lacuna::RPC::Building::WasteSequestration';

use constant image => 'wastesequestration';

use constant name => 'Waste Sequestration Well';

use constant university_prereq => 3;

use constant food_to_build => 10;

use constant energy_to_build => 10;

use constant ore_to_build => 10;

use constant water_to_build => 10;

use constant waste_to_build => 25;

use constant time_to_build => 45;

use constant waste_storage => 1000;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
