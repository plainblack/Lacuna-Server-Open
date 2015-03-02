package Lacuna::DB::Result::Building::Permanent::GasGiantPlatform;

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

use constant controller_class => 'Lacuna::RPC::Building::GasGiantPlatform';

use constant image => 'gas-giant-platform';

before 'can_demolish' => sub {
  my $self = shift;

  my $body = $self->body;
  return if ($body->get_type ne "gas giant");

  my $gg_plots = 0;
  my $gg_cnt = 0;
  my @buildings = grep {$_->class eq 'Lacuna::DB::Result::Building::Permanent::GasGiantPlatform'} @{$body->building_cache};
  foreach my $gg_bld (@buildings) {
    $gg_cnt++;
    $gg_plots += int($gg_bld->level * $gg_bld->efficiency/100);
  }
  return if ($gg_cnt <= 1); # If we only have the one platform, they can destroy it.
  my $bld_count = $body->building_count;
  my $excess_plots = $gg_plots - $bld_count;
  if ($excess_plots < 0) {
    confess [1013, 'Your Gas Giant shows that you are at negative plots.'];
  }
  if ($excess_plots < int($self->level * $self->efficiency/100) ) {
    confess [1013, 'You need to demolish a building before you can demolish this Gas Giant Settlement Platform.'];
  }
};

before 'can_downgrade' => sub {
  my $self = shift;
  my $body = $self->body;
  return if ($body->get_type ne "gas giant");

  my $gg_plots = 0;
  my $gg_cnt = 0;
  my @buildings = grep {$_->class eq 'Lacuna::DB::Result::Building::Permanent::GasGiantPlatform'} @{$body->building_cache};
  foreach my $gg_bld (@buildings) {
    $gg_cnt++;
    $gg_plots += int($gg_bld->level * $gg_bld->efficiency/100);
  }
  my $bld_count = $body->building_count;
  my $excess_plots = $gg_plots - $bld_count;
  if ($excess_plots < 1) {
    confess [1013, 'You need to demolish at least one building before you can downgrade this Gas Giant Settlement Platform.'];
  }
};

before has_special_resources => sub {
  my $self = shift;
  my $planet = $self->body;
  unless ($planet->get_plan(ref $self, $self->level + 1)) {
    my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.50);
    if ($planet->rutile_stored + $planet->chromite_stored +
      $planet->bauxite_stored + $planet->magnetite_stored +
      $planet->beryl_stored + $planet->goethite_stored < $amount_needed) {
        confess [1012,"You do not have a sufficient supply (".
          $amount_needed.
          ") of structural minerals such as Rutile, Chromite, Bauxite, Magnetite, Beryl, and Goethite to build the components that can handle the stresses of gas giant missions."];
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

use constant name => 'Gas Giant Settlement Platform';

use constant food_to_build => 0;

use constant energy_to_build => 1500;

use constant ore_to_build => 1500;

use constant water_to_build => 0;

use constant waste_to_build => 300;

use constant time_to_build => 250;

use constant waste_production => 110;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
