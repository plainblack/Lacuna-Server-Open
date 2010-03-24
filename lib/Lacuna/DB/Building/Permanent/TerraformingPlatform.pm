package Lacuna::DB::Building::Permanent::TerraformingPlatform;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Colonization));
};

use constant controller_class => 'Lacuna::Building::TerraformingPlatform';

sub check_build_prereqs {
    confess [1013,"You can't directly build a Terraforming Platform. You need a terraforming platform ship."];
}

use constant image => 'terraformingplatform';

use constant name => 'Terraforming Platform';

use constant food_to_build => 1000;

use constant energy_to_build => 1000;

use constant ore_to_build => 1000;

use constant water_to_build => 1000;

use constant waste_to_build => 1000;

use constant time_to_build => 600;

use constant food_consumption => 45;

use constant energy_consumption => 45;

use constant ore_consumption => 45;

use constant water_consumption => 45;

use constant waste_production => 100;

no Moose;
__PACKAGE__->meta->make_immutable;
