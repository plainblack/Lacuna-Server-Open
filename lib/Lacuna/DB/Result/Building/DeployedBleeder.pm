package Lacuna::DB::Result::Building::DeployedBleeder;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Util qw(randint);
use List::Util qw(shuffle);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES GROWTH INFLATION);

with 'Lacuna::Role::Building::IgnoresUniversityLevel';

use constant controller_class => 'Lacuna::RPC::Building::DeployedBleeder';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"If you want a Bleeder, build one at the Shipyard."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade a Deployed Bleeder."];
}

use constant image => 'deployedbleeder';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Deployed Bleeder';
use constant time_to_build => 15;

after finish_upgrade => sub {
    my $self = shift;
    $self->discard_changes;

    if ($self->level >= 30) {
        my $body_mult = $self->body;
        my ($x, $y) = eval{$body_mult->find_free_space};
        my $place = 0;
        if ($@) {
            my ($building) = shuffle grep {
                    ($_->class ne 'Lacuna::DB::Result::Building::Permanent::EssentiaVein') and
                    ($_->class ne 'Lacuna::DB::Result::Building::Permanent::TheDillonForge') and
                    ($_->class ne 'Lacuna::DB::Result::Building::Permanent::Fissure') and
                    !($_->class =~ /^Lacuna::DB::Result::Building::LCOT/) and
                    ($_->class ne 'Lacuna::DB::Result::Building::DeployedBleeder') and
                    ($_->class ne 'Lacuna::DB::Result::Building::PlanetaryCommand') and
                    ($_->class ne 'Lacuna::DB::Result::Building::Module::StationCommand') and
                    ($_->class ne 'Lacuna::DB::Result::Building::Module::Parliament')
            }
            @{$body_mult->building_cache};
            if ($building) {
                $place = 1;
                $building->downgrade(1);
            }
        }
        else {
            $place = 1;
            my $deployed = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
                class       => 'Lacuna::DB::Result::Building::DeployedBleeder',
                x           => $x,
                y           => $y,
            });
            $body_mult->build_building($deployed, 1);
            $deployed->finish_upgrade;
            $body_mult->needs_surface_refresh(1);
            $body_mult->update;
        }
        if ($place) {
            $self->level(29);
            $self->update;
        }
    }
    $self->start_upgrade(undef, 1) if ($self->level < 30);
};

sub finish_upgrade_news
{
    my ($self, $new_level, $empire) = @_;
    if ($new_level % 5 == 0) {
        my %levels = (5=>'shocked',10=>'stunned into silence',15=>'bewildered',20=>'dumbfounded',25=>'depressed',30=>'in great fear');
        $self->body->add_news($new_level*4,"Standing around %s, the citizens of %s watched as their %s grew on its own.", $levels{$new_level}, $empire->name, $self->name);
    }
}

sub cost_to_upgrade {
    my ($self) = @_;
    my $upgrade_cost = $self->upgrade_cost;
    my $upgrade_cost_reduction = $self->construction_cost_reduction_bonus;
    my $time_inflator = ($self->level * 2) - 1;
    $time_inflator = 1 if ($time_inflator < 1);
    my $throttle = Lacuna->config->get('building_build_speed') || 6;
    my $time_cost = (( $self->level+1)/$throttle * $self->time_to_build * $time_inflator ** INFLATION);
    $time_cost = 5184000 if ($time_cost > 5184000); # 60 Days
    $time_cost = 15 if ($time_cost < 15);

    return {
        food    => sprintf('%.0f',$self->food_to_build * $upgrade_cost * $upgrade_cost_reduction),
        energy  => sprintf('%.0f',$self->energy_to_build * $upgrade_cost * $upgrade_cost_reduction),
        ore     => sprintf('%.0f',$self->ore_to_build * $upgrade_cost * $upgrade_cost_reduction),
        water   => sprintf('%.0f',$self->water_to_build * $upgrade_cost * $upgrade_cost_reduction),
        waste   => sprintf('%.0f',$self->waste_to_build * $upgrade_cost * $upgrade_cost_reduction),
        time    => sprintf('%.0f',$time_cost),
    };
}

use constant food_consumption => 250;
use constant energy_consumption => 250;
use constant ore_consumption => 250;
use constant water_consumption => 250;
use constant waste_production => 1000;
use constant happiness_consumption => 1000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
