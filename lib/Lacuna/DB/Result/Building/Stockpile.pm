package Lacuna::DB::Result::Building::Stockpile;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Storage Food Water Ore Energy));
};

use constant max_instances_per_planet => 1;

use constant building_prereq => {'Lacuna::DB::Result::Building::Capitol'=>10};

use constant controller_class => 'Lacuna::RPC::Building::Stockpile';

use constant image => 'stockpile';

use constant name => 'Stockpile';

use constant food_to_build => 330;

use constant energy_to_build => 330;

use constant ore_to_build => 330;

use constant water_to_build => 330;

use constant waste_to_build => 100;

use constant time_to_build => 230;

use constant food_consumption => 2;

use constant energy_consumption => 5;

use constant ore_consumption => 1;

use constant water_consumption => 2;

use constant waste_production => 1;

use constant food_storage => 300;

use constant energy_storage => 300;

use constant ore_storage => 300;

use constant water_storage => 300;

before 'can_downgrade' => sub {
  my $self = shift;
  my $max_level = 15 + int(($self->effective_level-1)/3);
  if ($self->body->empire->university_level > 25) {
    $max_level += ($self->body->empire->university_level - 25);
  }
  foreach my $building (@{$self->body->building_cache}) {
    if ($building->level > $max_level &&
        'Resources' ~~ [$building->build_tags] &&
        ( !('Storage' ~~ [$building->build_tags]) ||
          $building->isa('Lacuna::DB::Result::Building::Waste::Exchanger'))) {
      confess [1013, 'You have to downgrade your level '.
                     $building->level.' '.$building->name.' to level '.
                     $max_level.' before you can downgrade the Stockpile.'];
    }
  }
};

before 'can_demolish' => sub {
  my $self = shift;
  my $max_level = 15;
  if ($self->body->empire->university_level > 25) {
    $max_level += ($self->body->empire->university_level - 25);
  }
  foreach my $building (@{$self->body->building_cache}) {
    if ($building->level > $max_level &&
        'Resources' ~~ [$building->build_tags] &&
        ( !('Storage' ~~ [$building->build_tags]) ||
          $building->isa('Lacuna::DB::Result::Building::Waste::Exchanger'))) {
     confess [1013, 'You have to downgrade your level '.
                    $building->level.' '.$building->name.
                    ' to level '.$max_level.
                    ' before you can demolish the Stockpile.'];
    }
  }
};

sub extra_resource_levels {
    my $self = shift;
    return int($self->effective_level / 3);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
