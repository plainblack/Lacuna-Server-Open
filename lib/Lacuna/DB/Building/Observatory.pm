package Lacuna::DB::Result::Building::Observatory;

use Moose;
extends 'Lacuna::DB::Result::Building';


around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships Intelligence Colonization));
};

use constant controller_class => 'Lacuna::Building::Observatory';

use constant university_prereq => 3;

use constant max_instances_per_planet => 1;

use constant image => 'observatory';

use constant name => 'Observatory';

use constant food_to_build => 63;

use constant energy_to_build => 63;

use constant ore_to_build => 63;

use constant water_to_build => 63;

use constant waste_to_build => 100;

use constant time_to_build => 300;

use constant food_consumption => 1;

use constant energy_consumption => 45;

use constant ore_consumption => 1;

use constant water_consumption => 1;

use constant waste_production => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
