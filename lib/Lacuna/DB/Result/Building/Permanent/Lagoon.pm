package Lacuna::DB::Result::Building::Permanent::Lagoon;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::Lagoon';

use constant image => 'lagoon';

use constant name => 'Lagoon';

use constant water_to_build => 1;
use constant ore_to_build => 1;
use constant time_to_build => 1;
use constant algae_production => 10; 
around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(algae);
    return $foods;
};
use constant water_production => 10;
use constant max_instances_per_planet => 9;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
