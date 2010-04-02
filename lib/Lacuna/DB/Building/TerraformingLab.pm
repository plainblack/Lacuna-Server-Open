package Lacuna::DB::Building::TerraformingLab;

use Moose;
extends 'Lacuna::DB::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Colonization Ships));
};

use constant controller_class => 'Lacuna::Building::TerraformingLab';

use constant university_prereq => 10;

use constant image => 'terraforminglab';

use constant name => 'Terraforming Lab';

use constant food_to_build => 310;

use constant energy_to_build => 340;

use constant ore_to_build => 310;

use constant water_to_build => 290;

use constant waste_to_build => 350;

use constant time_to_build => 1200;

use constant food_consumption => 50;

use constant energy_consumption => 100;

use constant ore_consumption => 25;

use constant water_consumption => 50;

use constant waste_production => 100;


no Moose;
__PACKAGE__->meta->make_immutable;
