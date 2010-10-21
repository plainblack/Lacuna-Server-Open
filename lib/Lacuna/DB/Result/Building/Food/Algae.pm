package Lacuna::DB::Result::Building::Food::Algae;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Energy));
};

use constant controller_class => 'Lacuna::RPC::Building::Algae';

use constant university_prereq => 2;

use constant image => 'algae';

use constant name => 'Algae Cropper';

use constant food_to_build => 10;

use constant energy_to_build => 115;

use constant ore_to_build => 105;

use constant water_to_build => 100;

use constant waste_to_build => 20;

use constant time_to_build => 55;

use constant food_consumption => 1;

use constant algae_production => 23;

use constant energy_production => 11;

use constant energy_consumption => 2;

use constant ore_consumption => 1;

use constant water_consumption => 3;

use constant waste_consumption => 1;

use constant waste_production => 1;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(algae);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
