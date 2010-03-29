package Lacuna::DB::Building::RND;

use Moose;
extends 'Lacuna::DB::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness));
};

use constant controller_class => 'Lacuna::Building::RND';

use constant university_prereq => 2;

use constant image => 'rnd';

use constant name => 'Research Lab';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 100;

use constant time_to_build => 300;

use constant food_consumption => 10;

use constant energy_consumption => 25;

use constant ore_consumption => 25;

use constant water_consumption => 10;

use constant waste_production => 15;

use constant happiness_production => 50;



no Moose;
__PACKAGE__->meta->make_immutable;
