package Lacuna::DB::Building::GasGiantLab;

use Moose;
extends 'Lacuna::DB::Building';

use constant controller_class => 'Lacuna::Building::GasGiantLab';

use constant university_prereq => 17;

use constant image => 'gas-giant-lab';

use constant name => 'Gas Giant Lab';

use constant food_to_build => 250;

use constant energy_to_build => 500;

use constant ore_to_build => 500;

use constant water_to_build => 100;

use constant waste_to_build => 250;

use constant time_to_build => 1200;

use constant food_consumption => 50;

use constant energy_consumption => 50;

use constant ore_consumption => 50;

use constant water_consumption => 50;

use constant waste_production => 100;


no Moose;
__PACKAGE__->meta->make_immutable;
