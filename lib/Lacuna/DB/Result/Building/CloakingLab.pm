package Lacuna::DB::Result::Building::CloakingLab;

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
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.07);
    if ($planet->chalcopyrite_stored + $planet->gold_stored + $planet->bauxite_stored < $amount_needed) {
        confess [1012,"You do not have a sufficient supply (".$amount_needed.") of conductive metals such as Chalcopyrite, Gold, and Bauxite to build cloaking systems."];
    }
};

use constant controller_class => 'Lacuna::RPC::Building::CloakingLab';

use constant university_prereq => 17;

use constant max_instances_per_planet => 1;

use constant image => 'cloakinglab';

use constant name => 'Cloaking Lab';

use constant food_to_build => 220;

use constant energy_to_build => 240;

use constant ore_to_build => 240;

use constant water_to_build => 220;

use constant waste_to_build => 100;

use constant time_to_build => 310;

use constant food_consumption => 14;

use constant energy_consumption => 50;

use constant ore_consumption => 20;

use constant water_consumption => 20;

use constant waste_production => 15;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
