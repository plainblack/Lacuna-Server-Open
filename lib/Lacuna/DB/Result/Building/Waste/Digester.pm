package Lacuna::DB::Result::Building::Waste::Digester;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Waste';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Ore));
};

use constant controller_class => 'Lacuna::RPC::Building::WasteDigester';

use constant image => 'wastedigester';

use constant university_prereq => 6;

use constant name => 'Waste Digester';

use constant food_to_build => 75;

use constant energy_to_build => 95;

use constant ore_to_build => 83;

use constant water_to_build => 95;

use constant waste_to_build => 20;

use constant time_to_build => 45;

use constant food_consumption => 5;

use constant energy_consumption => 5;

use constant ore_consumption => 5;
use constant ore_production => 40;

use constant water_consumption => 5;

use constant waste_consumption => 20;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
