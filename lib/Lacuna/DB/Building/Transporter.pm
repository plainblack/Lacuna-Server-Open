package Lacuna::DB::Building::Transporter;

use Moose;
extends 'Lacuna::DB::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
};

use constant controller_class => 'Lacuna::Building::Transporter';

use constant university_prereq => 12;

use constant image => 'transporter';

use constant name => 'Subspace Transporter';

use constant food_to_build => 700;

use constant energy_to_build => 800;

use constant ore_to_build => 900;

use constant water_to_build => 700;

use constant waste_to_build => 700;

use constant time_to_build => 1200;

use constant food_consumption => 25;

use constant energy_consumption => 50;

use constant ore_consumption => 15;

use constant water_consumption => 25;

use constant waste_production => 5;


no Moose;
__PACKAGE__->meta->make_immutable;
