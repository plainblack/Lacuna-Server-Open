package Lacuna::DB::Result::Building::Stockpile;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(GROWTH_F INFLATION_F CONSUME_N WASTE_F WASTE_N TINFLATE_F);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Storage Food Water Ore Energy));
};

use constant prod_rate => GROWTH_F;
use constant consume_rate => CONSUME_N;
use constant cost_rate => INFLATION_F;
use constant waste_prod_rate => WASTE_F;
use constant waste_consume_rate => WASTE_N;
use constant time_inflation => TINFLATE_F;

use constant max_instances_per_planet => 1;

use constant university_prereq => 10;

use constant controller_class => 'Lacuna::RPC::Building::Stockpile';

use constant image => 'stockpile';

use constant name => 'Stockpile';

use constant food_to_build => 300;

use constant energy_to_build => 400;

use constant ore_to_build => 600;

use constant water_to_build => 330;

use constant waste_to_build => 200;

use constant time_to_build => 230;

use constant food_consumption => 4;

use constant energy_consumption => 6;

use constant ore_consumption => 1;

use constant water_consumption => 2;

use constant waste_production => 2;

use constant food_storage => 500;

use constant energy_storage => 500;

use constant ore_storage => 500;

use constant water_storage => 500;

# before 'can_downgrade' => sub {
#   my $self = shift;
#   my $max_level = 15 + int(($self->effective_level-1)/3);
#   if ($self->body->empire->university_level > 25) {
#     $max_level += ($self->body->empire->university_level - 25);
#   }
#   foreach my $building (@{$self->body->building_cache}) {
#     if ($building->level > $max_level &&
#         'Resources' ~~ [$building->build_tags] &&
#         ( !('Storage' ~~ [$building->build_tags]) ||
#           $building->isa('Lacuna::DB::Result::Building::Waste::Exchanger'))) {
#       confess [1013, 'You have to downgrade your level '.
#                      $building->level.' '.$building->name.' to level '.
#                      $max_level.' before you can downgrade the Stockpile.'];
#     }
#   }
# };
# 
# before 'can_demolish' => sub {
#   my $self = shift;
#   my $max_level = 15;
#   if ($self->body->empire->university_level > 25) {
#     $max_level += ($self->body->empire->university_level - 25);
#   }
#   foreach my $building (@{$self->body->building_cache}) {
#     if ($building->level > $max_level &&
#         'Resources' ~~ [$building->build_tags] &&
#         ( !('Storage' ~~ [$building->build_tags]) ||
#           $building->isa('Lacuna::DB::Result::Building::Waste::Exchanger'))) {
#      confess [1013, 'You have to downgrade your level '.
#                     $building->level.' '.$building->name.
#                     ' to level '.$max_level.
#                     ' before you can demolish the Stockpile.'];
#     }
#   }
# };
# 
# sub extra_resource_levels {
#     my $self = shift;
#     return int($self->effective_level / 3);
# }

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
