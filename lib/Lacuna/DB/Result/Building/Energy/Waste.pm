package Lacuna::DB::Result::Building::Energy::Waste;

use Moose;
extends 'Lacuna::DB::Result::Building::Energy';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Waste));
};

before check_build_prereqs => sub {
    my $self = shift;
    my $planet = $self->body;
    if ($planet->zircon + $planet->beryl + $planet->gypsum < 100) {
        confess [1012,"This planet does not have a sufficient supply of insulating minerals such as Zircon, Beryl, and Gypsum to build a waste energy plant."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::WasteEnergy';

use constant image => 'wasteenergy';

use constant university_prereq => 4;

use constant name => 'Waste Energy Plant';

use constant food_to_build => 180;

use constant energy_to_build => 170;

use constant ore_to_build => 150;

use constant water_to_build => 190;

use constant waste_to_build => 20;

use constant time_to_build => 75;

use constant food_consumption => 2;

use constant energy_consumption => 22;

use constant energy_production => 65;

use constant ore_consumption => 1;

use constant water_consumption => 2;

use constant waste_consumption => 40;

use constant waste_production => 2;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
