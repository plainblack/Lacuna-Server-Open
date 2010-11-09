package Lacuna::DB::Result::Building::TerraformingLab;

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
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.20);
    if ($planet->gypsum_stored + $planet->sulfur_stored + $planet->monazite_stored < $amount_needed) {
        confess [1012,"You do not have a sufficient supply (".$amount_needed.") of phosphorus from sources like Gypsum, Sulfur, and Monazite to create the chemical compounds to terraform a planet."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::TerraformingLab';
use constant max_instances_per_planet => 1;

use constant university_prereq => 18;

use constant image => 'terraforminglab';

use constant name => 'Terraforming Lab';

use constant food_to_build => 310;

use constant energy_to_build => 340;

use constant ore_to_build => 310;

use constant water_to_build => 290;

use constant waste_to_build => 350;

use constant time_to_build => 600;

use constant food_consumption => 10;

use constant energy_consumption => 20;

use constant ore_consumption => 5;

use constant water_consumption => 10;

use constant waste_production => 20;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
