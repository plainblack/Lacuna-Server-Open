package Lacuna::DB::Result::Building::Permanent::GasGiantPlatform;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Construction));
};

use constant controller_class => 'Lacuna::RPC::Building::GasGiantPlatform';

use constant image => 'gas-giant-platform';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't directly build a Gas Giant Platform. You need a gas giant platform ship."];
};

before 'can_demolish' => sub {
    my $self = shift;
    if ($self->body->plots_available < $self->level) {
        confess [1013, 'You need to demolish a building before you can demolish this Gas Giant Settlement Platform.'];
    }
};

before 'can_downgrade' => sub {
    my $self = shift;
    if ($self->body->plots_available < 1) {
        confess [1013, 'You need to demolish a building before you can downgrade this Gas Giant Settlement Platform.'];
    }
};

before has_special_resources => sub {
    my $self = shift;
    my $planet = $self->body;
    unless ($planet->get_plan(ref $self, $self->level + 1)) {
        my $amount_needed = sprintf('%.0f', $self->ore_to_build * $self->upgrade_cost * 0.50);
        if ($planet->rutile_stored + $planet->chromite_stored + $planet->bauxite_stored + $planet->magnetite_stored + $planet->beryl_stored + $planet->goethite_stored < $amount_needed) {
            confess [1012,"You do not have a sufficient supply (".$amount_needed.") of structural minerals such as Rutile, Chromite, Bauxite, Magnetite, Beryl, and Goethite to build the components that can handle the stresses of gas giant missions."];
        }
    }
};

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
