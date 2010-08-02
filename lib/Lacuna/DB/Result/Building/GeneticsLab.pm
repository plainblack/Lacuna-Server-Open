package Lacuna::DB::Result::Building::GeneticsLab;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
};

use constant controller_class => 'Lacuna::RPC::Building::GeneticsLab';

use constant university_prereq => 20;

use constant image => 'geneticslab';

use constant name => 'Genetics Lab';

use constant food_to_build => 315;

use constant energy_to_build => 330;

use constant ore_to_build => 300;

use constant water_to_build => 280;

use constant waste_to_build => 300;

use constant time_to_build => 500;

use constant food_consumption => 15;

use constant energy_consumption => 30;

use constant ore_consumption => 5;

use constant water_consumption => 30;

use constant waste_production => 20;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
