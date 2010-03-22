package Lacuna::DB::Building::Food::Farm::Algae;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

use constant controller_class => 'Lacuna::Building::Algae';

use constant university_prereq => 3;

use constant image => 'algae';

use constant name => 'Algae Cropper';

use constant food_to_build => 10;

use constant energy_to_build => 100;

use constant ore_to_build => 55;

use constant water_to_build => 30;

use constant waste_to_build => 20;

use constant time_to_build => 110;

use constant food_consumption => 5;

use constant algae_production => 10;

use constant energy_production => 3;

use constant ore_consumption => 1;

use constant water_consumption => 2;

use constant waste_consumption => 5;

use constant waste_production => 6;



no Moose;
__PACKAGE__->meta->make_immutable;
