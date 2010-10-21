package Lacuna::DB::Result::Building::Energy::Hydrocarbon;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Energy';

before has_special_resources => sub {
    my $self = shift;
    my $planet = $self->body;
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.05);
    if ($planet->kerogen_stored + $planet->methane_stored + $planet->anthracite_stored < $amount_needed) {
        confess [1012,"You do not have a sufficient supply (".$amount_needed.") of hydrocarbons such as Kerogen, Methane, and Anthracite to operate this plant."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::Hydrocarbon';

use constant image => 'hydrocarbon';

use constant name => 'Hydrocarbon Energy Plant';

use constant university_prereq => 1;

use constant food_to_build => 300;

use constant energy_to_build => 260;

use constant ore_to_build => 330;

use constant water_to_build => 300;

use constant waste_to_build => 20;

use constant time_to_build => 55;

use constant food_consumption => 3;

use constant energy_consumption => 30;

use constant energy_production => 165;

use constant ore_consumption => 23;

use constant water_consumption => 3;

use constant waste_production => 75;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
