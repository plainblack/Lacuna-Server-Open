package Lacuna::DB::Result::Building::Food::Chip;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

use constant controller_class => 'Lacuna::RPC::Building::Chip';

use constant image => 'chips';

use constant building_prereq => {'Lacuna::DB::Result::Building::Food::Root'=>5};

use constant name => 'Denton Root Chip Frier';

use constant food_to_build => 160;

use constant energy_to_build => 160;

use constant ore_to_build => 160;

use constant water_to_build => 160;

use constant waste_to_build => 100;

use constant time_to_build => 100;

use constant food_consumption => 10;

use constant chip_production => 30;

use constant energy_consumption => 5;

use constant ore_consumption => 14;

use constant water_consumption => 5;

use constant waste_production => 24;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(chip);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
