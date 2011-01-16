package Lacuna::DB::Result::Building::Water::Reclamation;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Water';
with 'Lacuna::Role::WasteProcessor';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Waste));
};

before has_special_resources => sub {
    my $self = shift;
    my $planet = $self->body;
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.05);
    if ($planet->halite_stored + $planet->sulfur_stored < $amount_needed) {
        confess [1012,"You do not have a sufficient supply (".$amount_needed.") of mineral agents such as Halite and Sulfur for water treatment."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::WaterReclamation';

use constant university_prereq => 7;

use constant image => 'waterreclamation';

use constant name => 'Water Reclamation Facility';

use constant food_to_build => 175;

use constant energy_to_build => 191;

use constant ore_to_build => 175;

use constant water_to_build => 175;

use constant waste_to_build => 20;

use constant time_to_build => 90;

use constant food_consumption => 1;

use constant energy_consumption => 19;

use constant ore_consumption => 3;

use constant water_production => 60;

use constant water_consumption => 6;

use constant waste_consumption => 50;

use constant waste_production => 9;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
