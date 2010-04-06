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

use constant food_to_build => 300;

use constant energy_to_build => 260;

use constant ore_to_build => 330;

use constant water_to_build => 300;

use constant waste_to_build => 20;

use constant time_to_build => 130;

use constant food_consumption => 3;

use constant energy_consumption => 30;

use constant energy_production => 165;

use constant ore_consumption => 23;

use constant water_consumption => 3;

use constant waste_production => 75;



no Moose;
__PACKAGE__->meta->make_immutable;
