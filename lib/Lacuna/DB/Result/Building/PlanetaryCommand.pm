package Lacuna::DB::Result::Building::PlanetaryCommand;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
with 'Lacuna::Role::Building::IgnoresUniversityLevel';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Resources Ore Water Waste Energy Food Colonization Storage));
};

use constant controller_class => 'Lacuna::RPC::Building::PlanetaryCommand';

sub can_build {
    confess [1013,"You can't directly build a Planetary Command Center. You need a colony ship."];
}

before 'can_demolish' => sub {
   confess [1010, 'You cannot demolish the Planetary Command Center. Use the abandon colony function if you no longer want this colony.'];
};

before 'can_demolish' => sub {
    confess [1013, "You cannot demolish the Planetary Commmand Center."];
};

use constant image => 'command';

use constant name => 'Planetary Command Center';

use constant food_to_build => 320;

use constant energy_to_build => 320;

use constant ore_to_build => 320;

use constant water_to_build => 320;

use constant waste_to_build => 500;

use constant time_to_build => 300;

use constant algae_production => 10;

use constant energy_production => 10;

use constant ore_production => 10;

use constant water_production => 10;

use constant waste_production => 1;

use constant food_storage => 700;

use constant energy_storage => 700;

use constant ore_storage => 700;

use constant water_storage => 700;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(algae);
    return $foods;
};

sub incoming_supply_chains {
    my ($self) = @_;

    return Lacuna->db->resultset('Lacuna::DB::Result::SupplyChain')->search({ target_id => $self->body_id });
}

sub sent_a_pod
{
    my ($self) = @_;

    my $level    = $self->effective_level;
    my $cooldown = int(
                         28.747 * $level * $level
                       - 2877.4 * $level
                       + 89249.
                      );

    $self->start_work({}, $cooldown);
}

sub can_send_pod
{
    my ($self) = @_;
    ! $self->is_working;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
