package Lacuna::DB::Building::Observatory;

use Moose;
extends 'Lacuna::DB::Building';


around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships Intelligence Colonization));
};

use constant controller_class => 'Lacuna::Building::Observatory';

use constant building_prereq => {'Lacuna::DB::Building::Shipyard'=>1};

use constant image => 'observatory';

use constant name => 'Observatory';

use constant food_to_build => 150;

use constant energy_to_build => 150;

use constant ore_to_build => 150;

use constant water_to_build => 150;

use constant waste_to_build => 150;

use constant time_to_build => 300;

use constant food_consumption => 5;

use constant energy_consumption => 50;

use constant ore_consumption => 5;

use constant water_consumption => 15;

use constant waste_production => 2;


no Moose;
__PACKAGE__->meta->make_immutable;
