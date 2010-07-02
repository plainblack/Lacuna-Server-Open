package Lacuna::DB::Result::Building::Food::Malcud;

use Moose;
extends 'Lacuna::DB::Result::Building::Food';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Waste));
};

use constant controller_class => 'Lacuna::RPC::Building::Malcud';

use constant image => 'malcud';

use constant name => 'Malcud Fungus Farm';

use constant food_to_build => 10;

use constant energy_to_build => 60;

use constant ore_to_build => 46;

use constant water_to_build => 30;

use constant waste_to_build => 20;

use constant time_to_build => 57;

use constant food_consumption => 1;

use constant fungus_production => 20;

use constant energy_consumption => 1;

use constant ore_consumption => 1;

use constant water_consumption => 1;

use constant waste_consumption => 1;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
