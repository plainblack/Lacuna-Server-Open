package Lacuna::DB::Result::Building::PilotTraining;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships));
};

before has_special_resources => sub {
    my $self = shift;
    my $planet = $self->body;
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.01);
    if ($planet->gold_stored < $amount_needed) {
        confess [1012,"You do not have a sufficient supply (".$amount_needed.") of gold to adorn pilot uniforms."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::PilotTraining';

use constant university_prereq => 14;

use constant max_instances_per_planet => 1;

use constant image => 'pilottraining';

use constant name => 'Pilot Training Facility';

use constant food_to_build => 220;

use constant energy_to_build => 230;

use constant ore_to_build => 220;

use constant water_to_build => 230;

use constant waste_to_build => 100;

use constant time_to_build => 290;

use constant food_consumption => 25;

use constant energy_consumption => 25;

use constant ore_consumption => 20;

use constant water_consumption => 25;

use constant waste_production => 15;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
