package Lacuna::DB::Result::Building::Propulsion;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships));
};

before check_build_prereqs => sub {
    my $self = shift;
    my $planet = $self->body;
    if ($planet->rutile + $planet->chromite + $planet->bauxite + $planet->magnetite + $planet->beryl + $planet->goethite < 1000) {
        confess [1012,"This planet does not have a sufficient supply (1,000) of structural minerals such as Rutile, Chromite, Bauxite, Magnetite, Beryl, and Goethite to build better engines."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::Propulsion';

use constant university_prereq => 13;

use constant max_instances_per_planet => 1;

use constant image => 'propulsion';

use constant name => 'Propulsion System Factory';

use constant food_to_build => 220;

use constant energy_to_build => 220;

use constant ore_to_build => 220;

use constant water_to_build => 220;

use constant waste_to_build => 100;

use constant time_to_build => 300;

use constant food_consumption => 14;

use constant energy_consumption => 20;

use constant ore_consumption => 20;

use constant water_consumption => 20;

use constant waste_production => 15;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
