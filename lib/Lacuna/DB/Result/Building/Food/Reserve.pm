package Lacuna::DB::Result::Building::Food::Reserve;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Storage));
};

use constant controller_class => 'Lacuna::RPC::Building::FoodReserve';

use constant image => 'food-reserve';

use constant name => 'Food Reserve';

use constant university_prereq => 1;

use constant food_to_build => 45;

use constant energy_to_build => 45;

use constant ore_to_build => 45;

use constant water_to_build => 45;

use constant waste_to_build => 45;

use constant time_to_build => 60;

use constant food_consumption => 1;

use constant energy_consumption => 4;

use constant water_consumption => 1;

use constant waste_production => 1;

use constant food_storage => 1000;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
