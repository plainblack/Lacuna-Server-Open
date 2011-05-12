package Lacuna::DB::Result::Building::Permanent::TerraformingPlatform;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Construction));
};

use constant controller_class => 'Lacuna::RPC::Building::TerraformingPlatform';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't directly build a Terraforming Platform. You need a terraforming platform ship."];
};

before 'can_demolish' => sub {
    my $self = shift;
    my $body = $self->body;
    my $buildings = $body->buildings;
    my $terraforming_platforms = $buildings->->search({ class => 'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform' })->count;
    my $excess_plots = $terraforming_platforms - ($self->body->plots_available + $self->body->building_count);
    my $available = $excess_plots > $self->body->plots_available ? $excess_plots : $self->body->plots_available;
    if ($available < $self->level && ($body->orbit > $body->empire->max_orbit || $body->orbit < $body->empire->min_orbit)) {
        confess [1013, 'You need to demolish a building before you can demolish this Terraforming Platform.'];
    }
};

before 'can_downgrade' => sub {
    my $self = shift;
    my $body = $self->body;
    my $buildings = $body->buildings;
    my $terraforming_platforms = $buildings->->search({ class => 'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform' })->count;
    my $excess_plots = $terraforming_platforms - ($self->body->plots_available + $self->body->building_count);
    my $available = $excess_plots > $self->body->plots_available ? $excess_plots : $self->body->plots_available;
    if ($available < 1 && ($body->orbit > $body->empire->max_orbit || $body->orbit < $body->empire->min_orbit)) {
        confess [1013, 'You need to demolish a building before you can downgrade this Terraforming Platform.'];
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
