package Lacuna::DB::Result::Building::Energy::Singularity;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Energy';

use constant controller_class => 'Lacuna::RPC::Building::Singularity';

use constant image => 'singularity';

use constant university_prereq => 15;

use constant name => 'Singularity Energy Plant';

use constant food_to_build => 1000;

use constant energy_to_build => 1105;

use constant ore_to_build => 1400;

use constant water_to_build => 1100;

use constant waste_to_build => 1475;

use constant time_to_build => 600;

use constant food_consumption => 6;

use constant energy_consumption => 88;

use constant energy_production => 475;

use constant ore_consumption => 5;

use constant water_consumption => 6;
use constant max_instances_per_planet => 2;

use constant waste_production => 23;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
