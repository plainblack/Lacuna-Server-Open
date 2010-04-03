package Lacuna::DB::Building::Propulsion;

use Moose;
extends 'Lacuna::DB::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships));
};

use constant controller_class => 'Lacuna::Building::Propulsion';

use constant university_prereq => 3;

use constant max_instances_per_planet => 1;

use constant image => 'propulsion';

use constant name => 'Propulsion System Factory';

use constant food_to_build => 220;

use constant energy_to_build => 220;

use constant ore_to_build => 220;

use constant water_to_build => 220;

use constant waste_to_build => 100;

use constant time_to_build => 600;

use constant food_consumption => 14;

use constant energy_consumption => 20;

use constant ore_consumption => 20;

use constant water_consumption => 20;

use constant waste_production => 15;


no Moose;
__PACKAGE__->meta->make_immutable;
