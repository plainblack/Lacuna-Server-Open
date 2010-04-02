package Lacuna::DB::Building::Observatory;

use Moose;
extends 'Lacuna::DB::Building';


around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships Intelligence Colonization));
};

use constant controller_class => 'Lacuna::Building::Observatory';

use constant university_prereq => 3;

use constant image => 'observatory';

use constant name => 'Observatory';

use constant food_to_build => 63;

use constant energy_to_build => 63;

use constant ore_to_build => 63;

use constant water_to_build => 63;

use constant waste_to_build => 100;

use constant time_to_build => 300;

use constant food_consumption => 5;

use constant energy_consumption => 60;

use constant ore_consumption => 5;

use constant water_consumption => 6;

use constant waste_production => 2;


no Moose;
__PACKAGE__->meta->make_immutable;
