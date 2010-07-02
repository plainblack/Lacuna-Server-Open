package Lacuna::DB::Result::Building::Embassy;

use Moose;
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
};

use constant controller_class => 'Lacuna::RPC::Building::Embassy';

use constant max_instances_per_planet => 1;

use constant university_prereq => 5;

use constant image => 'embassy';

use constant name => 'Embassy';

use constant food_to_build => 65;

use constant energy_to_build => 65;

use constant ore_to_build => 65;

use constant water_to_build => 65;

use constant waste_to_build => 70;

use constant time_to_build => 150;

use constant food_consumption => 6;

use constant energy_consumption => 6;

use constant ore_consumption => 1;

use constant water_consumption => 6;

use constant waste_production => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
