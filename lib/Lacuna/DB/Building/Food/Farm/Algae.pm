package Lacuna::DB::Building::Food::Farm::Algae;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Energy));
};

use constant controller_class => 'Lacuna::Building::Algae';

use constant university_prereq => 2;

use constant image => 'algae';

use constant name => 'Algae Cropper';

use constant food_to_build => 10;

use constant energy_to_build => 100;

use constant ore_to_build => 55;

use constant water_to_build => 50;

use constant waste_to_build => 20;

use constant time_to_build => 110;

use constant food_consumption => 5;

use constant algae_production => 90;

use constant energy_production => 44;

use constant energy_consumption => 10;

use constant ore_consumption => 5;

use constant water_consumption => 10;

use constant waste_consumption => 5;

use constant waste_production => 6;



no Moose;
__PACKAGE__->meta->make_immutable;
