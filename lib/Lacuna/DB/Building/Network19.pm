package Lacuna::DB::Building::Network19;

use Moose;
extends 'Lacuna::DB::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness Intelligence));
};

use constant controller_class => 'Lacuna::Building::Network19';

use constant university_prereq => 2;

use constant image => 'network19';

use constant name => 'Network 19 Affliate';

use constant food_to_build => 98;

use constant energy_to_build => 98;

use constant ore_to_build => 100;

use constant water_to_build => 98;

use constant waste_to_build => 60;

use constant time_to_build => 300;

use constant food_consumption => 30;

use constant energy_consumption => 95;

use constant ore_consumption => 2;

use constant water_consumption => 40;

use constant waste_production => 15;

use constant happiness_production => 152;



no Moose;
__PACKAGE__->meta->make_immutable;
