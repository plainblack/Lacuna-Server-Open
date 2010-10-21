package Lacuna::DB::Result::Building::Oversight;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Construction));
};

use constant controller_class => 'Lacuna::RPC::Building::Oversight';

use constant max_instances_per_planet => 1;

use constant university_prereq => 8;

use constant image => 'oversight';

use constant name => 'Oversight Ministry';

use constant food_to_build => 50;

use constant energy_to_build => 50;

use constant ore_to_build => 50;

use constant water_to_build => 50;

use constant waste_to_build => 40;

use constant time_to_build => 150;

use constant food_consumption => 5;

use constant energy_consumption => 4;

use constant ore_consumption => 2;

use constant water_consumption => 5;

use constant waste_production => 3;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
