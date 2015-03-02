package Lacuna::DB::Result::Building::Permanent::TerraformingPlatform;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Lacuna::Constants qw(GROWTH);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::CantBuildWithoutPlan";

around 'build_tags' => sub {
  my ($orig, $class) = @_;
  return ($orig->($class), qw(Infrastructure Construction));
};

use constant controller_class => 'Lacuna::RPC::Building::TerraformingPlatform';

before 'can_demolish' => sub {
  my $self = shift;
  my $body = $self->body;
  return if ($body->orbit >= $body->empire->min_orbit && $body->orbit <= $body->empire->max_orbit);

  my $tp_plots = 0;
  my $tp_cnt = 0;

  my @buildings = grep {$_->class eq 'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform'} @{$body->building_cache};
  foreach my $tp_bld (@buildings) {
    $tp_cnt++;
    $tp_plots += int($tp_bld->level * $tp_bld->efficiency/100);
  }
  return if ($tp_cnt <= 1); # If we only have the one platform, they can destroy it.
  my $bld_count = $body->building_count;
  my $excess_plots = $tp_plots - $bld_count;
  if ($excess_plots < 0) {
    confess [1013, 'Your planet shows that you are at negative plots.'];
  }
  if ($excess_plots < int($self->level * $self->efficiency/100) ) {
    confess [1013, 'You need to demolish a building before you can demolish this Terraforming Platform.'];
  }
};

before 'can_downgrade' => sub {
  my $self = shift;
  my $body = $self->body;
  return if ($body->orbit >= $body->empire->min_orbit && $body->orbit <= $body->empire->max_orbit);

  my $tp_plots = 0;
  my $tp_cnt = 0;

  my @buildings = grep {$_->class eq 'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform'} @{$body->building_cache};
  foreach my $tp_bld (@buildings) {
    $tp_cnt++;
    $tp_plots += int($tp_bld->level * $tp_bld->efficiency/100);
  }
  return if ($tp_cnt <= 1); # If we only have the one platform, they can destroy it.
  my $bld_count = $body->building_count;
  my $excess_plots = $tp_plots - $bld_count;
  if ($excess_plots < 1) {
    confess [1013, 'You need to demolish at least one building before you can downgrade this Terraforming Platform.'];
  }
};

before has_special_resources => sub {
  my $self = shift;
  my $planet = $self->body;
  unless ($planet->get_plan(ref $self, $self->level + 1)) {
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.20);
    if ($planet->gypsum_stored + $planet->sulfur_stored + $planet->monazite_stored < $amount_needed) {
      confess [1012,"You do not have a sufficient supply (".$amount_needed.") of phosphorus from sources like Gypsum, Sulfur, and Monazite to create the chemical compounds to terraform a planet."];
    }
  }
};

sub production_hour {
    my $self = shift;
    return 0 unless  $self->level;
    my $prod_level = $self->level;
    my $production = (GROWTH ** (  $prod_level - 1));
    $production = ($production * $self->efficiency) / 100;
    return $production;
}

use constant image => 'terraformingplatform';

use constant name => 'Terraforming Platform';

use constant food_to_build => 0;

use constant energy_to_build => 800;

use constant ore_to_build => 800;

use constant water_to_build => 0;

use constant waste_to_build => 250;

use constant time_to_build => 180;

use constant waste_production => 60;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
