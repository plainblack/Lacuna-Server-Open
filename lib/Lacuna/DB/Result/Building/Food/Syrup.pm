package Lacuna::DB::Result::Building::Food::Syrup;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

use constant controller_class => 'Lacuna::RPC::Building::Syrup';

use constant image => 'syrup';

use constant building_prereq => {'Lacuna::DB::Result::Building::Food::Algae'=>5};

use constant name => 'Algae Syrup Bottler';

use constant food_to_build => 150;

use constant energy_to_build => 150;

use constant ore_to_build => 150;

use constant water_to_build => 150;

use constant waste_to_build => 95;

use constant time_to_build => 100;

use constant food_consumption => 10;

use constant syrup_production => 30;

use constant energy_consumption => 15;

use constant ore_consumption => 1;

use constant water_consumption => 5;

use constant waste_production => 21;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(syrup);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
