package Lacuna::DB::Result::Building::GasGiantLab;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Colonization Ships));
};

before has_special_resources => sub {
    my $self = shift;
    my $planet = $self->body;
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.40);
    if ($planet->rutile_stored + $planet->chromite_stored + $planet->bauxite_stored + $planet->magnetite_stored + $planet->beryl_stored + $planet->goethite_stored < $amount_needed) {
        confess [1012,"You do not have a sufficient supply (".$amount_needed.") of structural minerals such as Rutile, Chromite, Bauxite, Magnetite, Beryl, and Goethite to build the components that can handle the stresses of gas giant missions."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::GasGiantLab';
use constant max_instances_per_planet => 1;

use constant university_prereq => 19;

use constant image => 'gas-giant-lab';

use constant name => 'Gas Giant Lab';

use constant food_to_build => 300;

use constant energy_to_build => 300;

use constant ore_to_build => 340;

use constant water_to_build => 300;

use constant waste_to_build => 150;

use constant time_to_build => 600;

use constant food_consumption => 12;

use constant energy_consumption => 22;

use constant ore_consumption => 7;

use constant water_consumption => 12;

use constant waste_production => 22;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
