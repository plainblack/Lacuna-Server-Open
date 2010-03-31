package Lacuna::DB::Building::Energy::Hydrocarbon;

use Moose;
extends 'Lacuna::DB::Building::Energy';

before check_build_prereqs => sub {
    my $self = shift;
    my $planet = $self->body;
    if ($planet->kerogen + $planet->methane + $planet->anthracite < 500) {
        confess [1012,"This planet does not have a sufficient amount of hydrocarbons to operate this plant."];
    }
};

use constant controller_class => 'Lacuna::Building::Hydrocarbon';

use constant image => 'hydrocarbon';

use constant name => 'Hydrocarbon Energy Plant';

use constant university_prereq => 1;

use constant food_to_build => 100;

use constant energy_to_build => 10;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 20;

use constant time_to_build => 130;

use constant food_consumption => 15;

use constant energy_consumption => 120;

use constant energy_production => 560;

use constant ore_consumption => 90;

use constant water_consumption => 15;

use constant waste_production => 400;



no Moose;
__PACKAGE__->meta->make_immutable;
