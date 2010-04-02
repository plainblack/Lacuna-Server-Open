package Lacuna::DB::Building::Energy::Fission;

use Moose;
extends 'Lacuna::DB::Building::Energy';

before check_build_prereqs => sub {
    my $self = shift;
    my $planet = $self->body;
    if ($planet->uraninite + $planet->monazite < 500) {
        confess [1012,"This planet does not have a sufficient amount of radioactive minerals to operate this plant."];
    }
};

use constant controller_class => 'Lacuna::Building::Fission';

use constant university_prereq => 6;

use constant image => 'fission';

use constant name => 'Fission Energy Plant';

use constant food_to_build => 250;

use constant energy_to_build => 365;

use constant ore_to_build => 365;

use constant water_to_build => 330;

use constant waste_to_build => 150;

use constant time_to_build => 400;

use constant food_consumption => 5;

use constant energy_consumption => 70;

use constant energy_production => 570;

use constant ore_consumption => 35;

use constant water_consumption => 50;

use constant waste_production => 70;



no Moose;
__PACKAGE__->meta->make_immutable;
