package Lacuna::DB::Result::Building::Waste::Treatment;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Waste';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Energy Ore Water));
};

before has_special_resources => sub {
    my $self = shift;
    my $planet = $self->body;
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.05);
    if ($planet->halite_stored + $planet->sulfur_stored + $planet->trona_stored < $amount_needed) {
        confess [1012,"You do not have a sufficient supply (".$amount_needed.") of mineral agents such as Halite, Sulfur, and Trona for waste treatment."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::WasteTreatment';

use constant image => 'wastetreatment';

use constant university_prereq => 5;

use constant name => 'Waste Treatment Center';

use constant food_to_build => 75;

use constant energy_to_build => 95;

use constant ore_to_build => 83;

use constant water_to_build => 95;

use constant waste_to_build => 20;

use constant time_to_build => 150;

use constant food_consumption => 1;

use constant energy_consumption => 2;

use constant energy_production => 14;

use constant ore_consumption => 2;

use constant ore_production => 14;

use constant water_consumption => 2;

use constant water_production => 14;

use constant waste_consumption => 40;

use constant waste_production => 2;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
