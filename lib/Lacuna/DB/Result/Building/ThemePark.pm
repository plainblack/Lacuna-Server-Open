package Lacuna::DB::Result::Building::ThemePark;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use DateTime;
use Lacuna::Constants qw(FOOD_TYPES);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness));
};


use constant controller_class => 'Lacuna::RPC::Building::ThemePark';

use constant university_prereq => 16;

use constant image => 'themepark';

use constant name => 'Theme Park';

use constant food_to_build => 500;

use constant energy_to_build => 1005;

use constant ore_to_build => 900;

use constant water_to_build => 715;

use constant waste_to_build => 995;

use constant time_to_build => 300;

use constant food_consumption => 125;

use constant energy_consumption => 130;

use constant ore_consumption => 15;

use constant water_consumption => 150;

use constant waste_production => 115;

use constant happiness_production => 0;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
