package Lacuna::DB::Result::Building::Shipyard;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Util qw(format_date);
use DateTime;

around 'build_tags' => sub {
    my ($orig, $class) = @_;

    return ($orig->($class), qw(Infrastructure Ships));
};

# get fleets under construction at this shipyard resultset
sub fleets_under_construction {
    my ($self) = @_;

    return Lacuna->db->resultset('Fleet')->search({
        shipyard_id => $self->id,
        task        => 'Building',
    });
}

# get the costs to construct a fleet
sub get_fleet_costs {
    my ($self, $fleet) = @_;

    my $body = $self->body;
    my $percentage_of_cost = 100; 
    if ($fleet->base_hold_size) {
        my $trade = $self->body->trade;
        if (defined $trade) {
            $percentage_of_cost += $trade->effective_level * 3;
        }
    }
    if ($fleet->base_combat) {
        my $munitions_lab = $self->body->munitions_lab;
        if (defined $munitions_lab) {
            $percentage_of_cost += $munitions_lab->level * 3;
        }
    }
    if ($fleet->base_stealth) {
        my $cloak = $self->body->cloaking_lab;
        if (defined $cloak) {
            $percentage_of_cost += $cloak->effective_level * 3;
        }
    }
    if ($fleet->pilotable) {
        my $pilot = $self->body->pilot_training;
        if (defined $pilot) {
            $percentage_of_cost += $pilot->effective_level * 3;
        }
    }
    my $propulsion = $self->body->propulsion;
    if (defined $propulsion) {
        $percentage_of_cost += $propulsion->effective_level * 3;
    }
    $percentage_of_cost /= 100;
    my $throttle = Lacuna->config->get('ship_build_speed') || 0;
    my $seconds = $fleet->quantity
        * (1 - ($fleet->quantity / 50 * 0.03))
        * $fleet->base_time_cost 
        * $self->time_cost_reduction_bonus(($self->level * 3) + $throttle);

    $seconds = sprintf('%0.f', $seconds);
    $seconds = 15 if $seconds < 15;
    $seconds = 5184000 if ($seconds > 5184000); # 60 Days
    $seconds *= $self->body->build_boost;
    $seconds = 15 if $seconds < 15;
    my $bonus = $self->manufacturing_cost_reduction_bonus;
    return {
        seconds => $seconds,
        food    => sprintf('%0.f', $fleet->quantity * $fleet->base_food_cost * $percentage_of_cost * $bonus),
        water   => sprintf('%0.f', $fleet->quantity * $fleet->base_water_cost * $percentage_of_cost * $bonus),
        ore     => sprintf('%0.f', $fleet->quantity * $fleet->base_ore_cost * $percentage_of_cost * $bonus),
        energy  => sprintf('%0.f', $fleet->quantity * $fleet->base_energy_cost * $percentage_of_cost * $bonus),
        waste   => sprintf('%0.f', $fleet->quantity * $fleet->base_waste_cost * $percentage_of_cost),
    };
}

# The maximum number of ships that can be in a ship building queue
has max_ships => (
    is  => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;

        return Lacuna->db->resultset('Lacuna::DB::Result::Building')->search( {
            class       => $self->class, 
            body_id     => $self->body_id,
            efficiency  => 100,
        } )->get_column('level')->sum + 0;
    },
);

# Check if we can build this fleet
sub can_build_fleet {
    my ($self, $fleet, $costs) = @_;

    if (ref $fleet eq 'Lacuna::DB::Result::Fleet') {
        confess [1002, 'That is an unknown ship type.'];
    }
    $fleet->body_id($self->body_id);
    $fleet->shipyard_id($self->id);
    my $fleets = Lacuna->db->resultset('Lacuna::DB::Result::Fleet');
    $costs ||= $self->get_fleet_costs($fleet);
    if ($self->level < 1) {
        confess [1013, "You can't build a fleet if the shipyard isn't complete."];
    }
    my $reason = '';
    for my $prereq (@{$fleet->prereq}) {
        my $count = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search({
            body_id => $self->body_id,
            class   => $prereq->{class},
            level   => { '>=' => $prereq->{level} },
        })->count;
        if ($count == 0) {
            if ($reason eq '') {
                $reason = 'You need a level '.$prereq->{level}.' '.$prereq->{class}->name;
            }
            else {
                $reason .= ' and a level '.$prereq->{level}.' '.$prereq->{class}->name;
            }
        }
>>>>>>> Went through Planet/Body/Shipyard/SpacePort converting code to use fleets
    }
    if ($reason ne '') {
        confess [1013, "$reason" ];
    }
    my $body = $self->body;
    foreach my $key (keys %{$costs}) {
        next if ($key eq 'seconds' || $key eq 'waste');
        if ($costs->{$key} > $body->type_stored($key)) {
            confess [1011, 'Not enough resources.', $key];
        }
    }
    
    my ($sum) = $fleets->search({
        body_id => $self->body_id,
        task    => 'Building',
        }, {
        "+select" => [
            { count => 'id' },
            { sum   => 'quantity' },
        ],
        "+as" => [qw(number_of_fleets number_of_ships)],
    });

    if ($sum->get_column('number_of_ships') + $fleet->quantity > $self->max_ships) {
        confess [1013, 'You can only have '.$self->max_ships.' ships in the queue at this shipyard. Upgrade the shipyard to support more ships.'];
    }
    if ($self->body->spaceport->docks_available < $fleet->quantity) {
        confess [1009, "You do not have ".$fleet->quantity." docks available at the Spaceport."];
    }
    return 1;
}

# Return a result set of all fleets building at this Shipyard
sub building_fleets {
    my ($self) = @_;

    return Lacuna->db->resultset('Lacuna::DB::Result::Fleet')->search({
        shipyard_id => $self->id, 
        task        => 'Building',
    });
}

# deduct the cost of the fleet from the colony
sub spend_resources_to_build_fleet {
    my ($self, $costs) = @_;

    my $body = $self->body;
    foreach my $key (keys %{ $costs }) {
        next if $key eq 'seconds';
        if ($key eq 'waste') {
            $body->add_waste($costs->{waste});
        }
        else {
            my $spend = 'spend_'.$key;
            $body->$spend($costs->{$key});
        }
    }
    $body->update;
}

# Build a fleet
sub build_fleet {
    my ($self, $fleet, $time) = @_;

    $fleet->task('Building');
    $fleet->name($fleet->type_formatted);
    $fleet->body_id($self->body_id);
    $fleet->shipyard_id($self->id);
    $self->set_fleet_speed($fleet);
    $self->set_fleet_combat($fleet);
    $self->set_fleet_hold_size($fleet);
    $fleet->berth_level($fleet->base_berth_level);
    $self->set_fleet_stealth($fleet);
    $time ||= $self->get_fleet_costs($fleet)->{seconds};

    my $latest = $self->building_fleets->search(
        undef, { 
        order_by    => { -desc => 'date_available' }, 
        rows        => 1,
    })->single;

    my $now = DateTime->now;
    my $date_completed = $now;
    if (defined $latest) {
        $is_working=1;
        $date_completed = $latest->date_available->clone;
    }
    $date_completed->add( seconds => $time );
    $fleet->date_available($date_completed);
    $fleet->date_started($now);
    $fleet->insert;
    $self->start_work({}, $date_completed->epoch - time())->update;
    return $fleet;
}

use constant controller_class               => 'Lacuna::RPC::Building::Shipyard';
use constant building_prereq                => {'Lacuna::DB::Result::Building::SpacePort'=>1};
use constant image                          => 'shipyard';
use constant name                           => 'Shipyard';
use constant food_to_build                  => 75;
use constant energy_to_build                => 75;
use constant ore_to_build                   => 75;
use constant water_to_build                 => 75;
use constant waste_to_build                 => 100;
use constant time_to_build                  => 150;
use constant food_consumption               => 4;
use constant energy_consumption             => 6;
use constant ore_consumption                => 6;
use constant water_consumption              => 4;
use constant waste_production               => 2;
use constant star_to_body_distance_ratio    => 100;

# Get the pilot_training_level
sub ptf_level {
    my ($self, $fleet) = @_;

    return ($fleet->pilotable && defined $self->body->pilot_training) ? $self->body->pilot_training->level : 0;
}

# get the maximum shipyard level
sub shipyard_level {
    my ($self, $fleet) = @_;

    return (defined $self->body->shipyard) ? $self->body->shipyard->level : 0;
}

# get the crashed ship site level
sub css_level {
    my ($self, $fleet) = @_;

    return (defined $self->body->crashed_ship_site) ? $self->body->crashed_ship_site->level : 0;
}

# get the propulsion lab level
sub propulsion_level {
    my ($self, $fleet) = @_;

    return (defined $self->body->propulsion) ? $self->body->propulsion->level : 0;
}

# get the munitions lab level
sub munitions_level {
    my ($self, $fleet) = @_;

    return (defined $self->body->munitions_lab) ? $self->body->munitions_lab->level : 0;
}

# get the trade ministry level
sub trade_level {
    my ($self, $fleet) = @_;

    return (defined $self->body->trade) ? $self->body->trade->level : 0.1;
}

# get the cloaking lab level
sub cloaking_level {
    my ($self, $fleet) = @_;

    return (defined $self->body->cloaking_lab) ? $self->body->cloaking_lab->level : 0;
}

# Set the speed of a fleet
sub set_fleet_speed {
    my ($self, $fleet) = @_;

    my $improvement      = 1 
        + ($self->shipyard_level    * 0.01) 
        + ($self->ptf_level($fleet) * 0.03) 
        + ($self->propulsion_level  * 0.05) 
        + ($self->css_level         * 0.05) 
        + ($self->body->empire->science_affinity * 0.03);

    $fleet->speed(sprintf('%.0f', $fleet->base_speed * $improvement));
    return $fleet->speed;
}

# Set the fleet combat rating
sub set_fleet_combat {
    my ($self, $fleet) = @_;

    my $improvement = 1
        + ($self->shipyard_level    * 0.01)
        + ($self->ptf_level($fleet) * 0.03)
        + ($self->munitions_level   * 0.05)
        + ($self->css_level         * 0.05)
        + ($self->body->empire->deception_affinity * 0.03)
        + ($self->body->empire->science_affinity * 0.03);

    $fleet->combat(sprintf('%.0f', $fleet->base_combat * $improvement));
    return $fleet->combat;
}

# Set the fleet hold size
sub set_fleet_hold_size {
    my ($self, $fleet) = @_;

    my $improvement = 1
        + ($self->shipyard_level    * 0.01)
        + ($self->css_level         * 0.05);
    my $trade_bonus = $self->body->empire->trade_affinity * $self->trade_level;

    $fleet->hold_size(sprintf('%.0f', $fleet->base_hold_size * $trade_bonus * $improvement));
    return $fleet->hold_size;
}

# Set the fleet stealth
sub set_fleet_stealth {
    my ($self, $fleet) = @_;

    my $improvement = 1
        + ($self->shipyard_level     * 0.01)
        + ($self->ptf_level($fleet)  * 0.03)
        + ($self->cloaking_level     * 0.05)
        + ($self->css_level          * 0.05)
        + ($self->body->empire->deception_affinity * 0.03);

    $fleet->stealth(sprintf('%.0f', $fleet->base_stealth * $improvement ));
    return $fleet->stealth;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
