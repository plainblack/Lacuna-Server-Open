package Lacuna::DB::Building::Trade;

use Moose;
extends 'Lacuna::DB::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships));
};

use constant controller_class => 'Lacuna::Building::Trade';

use constant max_instances_per_planet => 1;

use constant university_prereq => 5;

use constant image => 'trade';

use constant name => 'Trade Ministry';

use constant food_to_build => 75;

use constant energy_to_build => 75;

use constant ore_to_build => 75;

use constant water_to_build => 75;

use constant waste_to_build => 80;

use constant time_to_build => 300;

use constant food_consumption => 5;

use constant energy_consumption => 28;

use constant ore_consumption => 2;

use constant water_consumption => 5;

use constant waste_production => 1;


no Moose;
__PACKAGE__->meta->make_immutable;
