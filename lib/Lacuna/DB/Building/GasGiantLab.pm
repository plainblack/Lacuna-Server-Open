package Lacuna::DB::Building::GasGiantLab;

use Moose;
extends 'Lacuna::DB::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Colonization Ships));
};

use constant controller_class => 'Lacuna::Building::GasGiantLab';

use constant university_prereq => 17;

use constant image => 'gas-giant-lab';

use constant name => 'Gas Giant Lab';

use constant food_to_build => 300;

use constant energy_to_build => 300;

use constant ore_to_build => 340;

use constant water_to_build => 300;

use constant waste_to_build => 150;

use constant time_to_build => 1200;

use constant food_consumption => 60;

use constant energy_consumption => 110;

use constant ore_consumption => 35;

use constant water_consumption => 60;

use constant waste_production => 110;


no Moose;
__PACKAGE__->meta->make_immutable;
