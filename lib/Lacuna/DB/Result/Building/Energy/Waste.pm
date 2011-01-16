package Lacuna::DB::Result::Building::Energy::Waste;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Energy';
with 'Lacuna::Role::WasteProcessor';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Waste));
};

before has_special_resources => sub {
    my $self = shift;
    my $planet = $self->body;
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.01);
    if ($planet->zircon_stored + $planet->beryl_stored + $planet->gypsum_stored < $amount_needed) {
        confess [1012,"You do not have a sufficient supply (".$amount_needed.") of insulating minerals such as Zircon, Beryl, and Gypsum to build and operate a waste energy plant."];
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
