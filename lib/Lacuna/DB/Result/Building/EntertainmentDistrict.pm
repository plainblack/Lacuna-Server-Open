package Lacuna::DB::Result::Building::EntertainmentDistrict;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness));
};

use constant controller_class => 'Lacuna::RPC::Building::Entertainment';

use constant university_prereq => 4;

use constant image => 'entertainment';

use constant name => 'Entertainment District';

use constant food_to_build => 160;

use constant energy_to_build => 160;

use constant ore_to_build => 190;

use constant water_to_build => 160;

use constant waste_to_build => 50;

use constant time_to_build => 150;

use constant food_consumption => 20;

use constant energy_consumption => 20;

use constant ore_consumption => 2;

use constant water_consumption => 20;

use constant waste_production => 16;

use constant happiness_production => 46;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
