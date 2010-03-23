package Lacuna::DB::Building::Transporter;

use Moose;
extends 'Lacuna::DB::Building';

use constant controller_class => 'Lacuna::Building::Transporter';

use constant university_prereq => 12;

use constant image => 'transporter';

use constant name => 'Subspace Transporter';

use constant food_to_build => 1200;

use constant energy_to_build => 1400;

use constant ore_to_build => 1500;

use constant water_to_build => 1200;

use constant waste_to_build => 900;

use constant time_to_build => 1200;

use constant food_consumption => 5;

use constant energy_consumption => 20;

use constant ore_consumption => 13;

use constant water_consumption => 20;

use constant waste_production => 2;


no Moose;
__PACKAGE__->meta->make_immutable;
