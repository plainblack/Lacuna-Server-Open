package Lacuna::DB::Result::Building::Energy::Reserve;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Energy';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Storage));
};

use constant controller_class => 'Lacuna::RPC::Building::EnergyReserve';

use constant university_prereq => 1;

use constant image => 'energy-reserve';

use constant name => 'Energy Reserve';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 200;

use constant time_to_build => 60;

use constant food_consumption => 1;

use constant energy_consumption => 6;

use constant ore_consumption => 1;

use constant water_consumption => 1;

use constant waste_production => 1;

use constant energy_storage => 1000;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
