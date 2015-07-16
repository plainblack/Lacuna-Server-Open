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


sub get_ship_costs {
    my ($self, $ship) = @_;
    my $body = $self->body;
    my $percentage_of_cost = 100; 
    if ($ship->base_hold_size) {
        my $trade = $self->trade_ministry;
        if (defined $trade) {
            $percentage_of_cost += $trade->effective_level * 3;
        }
    }
    if ($ship->base_combat) {
        my $munitions = $self->munitions_lab;
        if (defined $munitions) {
            $percentage_of_cost += $munitions->effective_level * 3;
        }
    }
    if ($ship->base_stealth) {
        my $cloak = $self->cloaking_lab;
        if (defined $cloak) {
            $percentage_of_cost += $cloak->effective_level * 3;
        }
    }
    if ($ship->pilotable) {
        my $pilot = $self->pilot_training_facility;
        if (defined $pilot) {
            $percentage_of_cost += $pilot->effective_level * 3;
        }
    }
    my $propulsion = $self->propulsion_factory;
    if (defined $propulsion) {
        $percentage_of_cost += $propulsion->effective_level * 3;
    }
    $percentage_of_cost /= 100;
    my $throttle = Lacuna->config->get('ship_build_speed') || 0;
    my $seconds = sprintf('%0.f', $ship->base_time_cost * $self->time_cost_reduction_bonus(($self->effective_level * 3) + $throttle));
    $seconds = 5184000 if ($seconds > 5184000); # 60 Days
    $seconds *= $self->body->build_boost;
    $seconds = 15 if $seconds < 15;
    my $bonus = $self->manufacturing_cost_reduction_bonus;
    return {
        seconds => int($seconds),
        food    => sprintf('%0.f', $ship->base_food_cost * $percentage_of_cost * $bonus),
        water   => sprintf('%0.f', $ship->base_water_cost * $percentage_of_cost * $bonus),
        ore     => sprintf('%0.f', $ship->base_ore_cost * $percentage_of_cost * $bonus),
        energy  => sprintf('%0.f', $ship->base_energy_cost * $percentage_of_cost * $bonus),
        waste   => sprintf('%0.f', $ship->base_waste_cost * $percentage_of_cost),
    };
}

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

sub can_build_ship {
  my ($self, $ship, $costs, $quantity) = @_;
  $quantity = defined $quantity ? $quantity : 1;

  if (ref $ship eq 'Lacuna::DB::Result::Ships') {
    confess [1002, 'That is an unknown ship type.'];
  }
  $ship->body_id($self->body_id);
  $ship->shipyard_id($self->id);
  my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
  $costs ||= $self->get_ship_costs($ship);
  if ($self->effective_level < 1) {
    confess [1013, "You can't build a ship if the shipyard isn't complete."];
  }
  my $reason = '';
  for my $prereq (@{$ship->prereq}) {
    my $count = Lacuna->db->resultset('Lacuna::DB::Result::Building')
                  ->search( { body_id => $self->body_id,
                              class => $prereq->{class},
                              level => {'>=' => $prereq->{level}} } )->count;
    unless ($count) {
      if ($reason eq '') {
        $reason = 'You need a level '.$prereq->{level}.' '.$prereq->{class}->name;
      }
      else {
        $reason .= ' and a level '.$prereq->{level}.' '.$prereq->{class}->name;
      }
    }
  }
  if ($reason ne '') {
    confess [1013, "$reason" ];
  }
  my $body = $self->body;
  foreach my $key (keys %{$costs}) {
    next if ($key eq 'seconds' || $key eq 'waste');
    my $cost = $costs->{$key} * $quantity;
    unless ($cost <= $body->type_stored($key)) {
      confess [1011, 'Not enough resources.', $key];
    }
  }
  my $ships_building = $ships->search({body_id => $self->body_id, task=>'Building'})->count;
  if ($ships_building + $quantity > $self->max_ships) {
    confess [1013, 'You can only have '.$self->max_ships.' ships in the queue at this shipyard. Upgrade the shipyard to support more ships.'];
  }
  unless ($self->body->spaceport->docks_available >= $quantity) {
    confess [1009, "You do not have $quantity docks available at the Spaceport."];
  }
  return 1;
}

sub building_ships {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ shipyard_id => $self->id, task => 'Building' });
}

sub spend_resources_to_build_ship {
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

sub build_ship {
    my ($self, $ship, $time) = @_;
    $ship->task('Building');
    my $name = $ship->type_formatted;
    $ship->name($name);
    $ship->body_id($self->body_id);
    $ship->shipyard_id($self->id);
    $self->set_ship_speed($ship);
    $self->set_ship_combat($ship);
    $self->set_ship_hold_size($ship);
    $ship->berth_level($ship->base_berth_level);
    $self->set_ship_stealth($ship);
    $time ||= $self->get_ship_costs($ship)->{seconds};
    my $latest = $self->building_ships->search(undef, { order_by    => { -desc => 'date_available' }})->first;
    my $date_completed;
    my $is_working;
    if (defined $latest) {
        $is_working=1;
        $date_completed = $latest->date_available->clone;
    }
    else {
        $date_completed = DateTime->now;
    }
    $date_completed->add(seconds=>$time);

    $ship->date_available($date_completed);
    $ship->date_started(DateTime->now);
    $ship->insert;
    $ship->start_construction;

    if ($is_working) {
        $self->reschedule_work($date_completed);
    }
    else {
        $self->start_work({}, $date_completed->epoch - time());
    }
    $self->update;
    return $ship;
}

use constant controller_class => 'Lacuna::RPC::Building::Shipyard';

use constant building_prereq => {'Lacuna::DB::Result::Building::SpacePort'=>1};

use constant image => 'shipyard';

use constant name => 'Shipyard';

use constant food_to_build => 75;

use constant energy_to_build => 75;

use constant ore_to_build => 75;

use constant water_to_build => 75;

use constant waste_to_build => 100;

use constant time_to_build => 150;

use constant food_consumption => 4;

use constant energy_consumption => 6;

use constant ore_consumption => 6;

use constant water_consumption => 4;

use constant waste_production => 2;

use constant star_to_body_distance_ratio => 100;


has cloaking_lab => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->body->get_building_of_class('Lacuna::DB::Result::Building::CloakingLab');
    },
);

has crashed_ship_site => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->body->get_building_of_class('Lacuna::DB::Result::Building::Permanent::CrashedShipSite');
    },
);

has pilot_training_facility => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->body->get_building_of_class('Lacuna::DB::Result::Building::PilotTraining');
    },
);

has propulsion_factory => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->body->get_building_of_class('Lacuna::DB::Result::Building::Propulsion');
    },
);

has trade_ministry => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->body->get_building_of_class('Lacuna::DB::Result::Building::Trade');
    },
);

has munitions_lab => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->body->get_building_of_class('Lacuna::DB::Result::Building::MunitionsLab');
    },
);

sub set_ship_speed {
    my ($self, $ship) = @_;
    my $propulsion_level = (defined $self->propulsion_factory) ? $self->propulsion_factory->effective_level : 0;
    my $css_level = (defined $self->crashed_ship_site) ? $self->crashed_ship_site->effective_level : 0;
    my $ptf = ($ship->pilotable && defined $self->pilot_training_facility) ? $self->pilot_training_facility->effective_level : 0;
    my $improvement = 1 + ($self->effective_level * 0.01) + ($ptf * 0.03) + ($propulsion_level * 0.05) + ($css_level * 0.05) + ($self->body->empire->effective_science_affinity * 0.03);
    $ship->speed(sprintf('%.0f', $ship->base_speed * $improvement));
    return $ship->speed;
}

sub set_ship_combat {
    my ($self, $ship) = @_;
    my $css_level = (defined $self->crashed_ship_site) ? $self->crashed_ship_site->effective_level : 0;
    my $munitions = (defined $self->munitions_lab) ? $self->munitions_lab->effective_level : 0;
    my $ptf = ($ship->pilotable && defined $self->pilot_training_facility) ? $self->pilot_training_facility->effective_level : 0;
    my $improvement = 1 + ($self->effective_level * 0.01) + ($ptf * 0.03) + ($munitions * 0.05) + ($css_level * 0.05) + ($self->body->empire->effective_deception_affinity * 0.03) + ($self->body->empire->effective_science_affinity * 0.03);
    $ship->combat(sprintf('%.0f', $ship->base_combat * $improvement));
    return $ship->combat;
}

sub set_ship_hold_size {
    my ($self, $ship) = @_;
    my $trade_ministry_level = (defined $self->trade_ministry) ? $self->trade_ministry->effective_level : 0;
    my $css_level = (defined $self->crashed_ship_site) ? $self->crashed_ship_site->effective_level : 0;
    my $improvement = 1 + ($self->effective_level * 0.01) + ($css_level * 0.05);
    my $trade_bonus = $self->body->empire->effective_trade_affinity * ( $trade_ministry_level || 0.1 );
    $ship->hold_size(sprintf('%.0f', $ship->base_hold_size * $trade_bonus * $improvement));
    return $ship->hold_size;
}

sub set_ship_stealth {
    my ($self, $ship) = @_;
    my $cloaking_level = (defined $self->cloaking_lab) ? $self->cloaking_lab->effective_level : 0;
    my $ptf = ($ship->pilotable && defined $self->pilot_training_facility) ? $self->pilot_training_facility->effective_level : 0;
    my $css_level = (defined $self->crashed_ship_site) ? $self->crashed_ship_site->effective_level : 0;
    my $improvement = 1 + ($self->effective_level * 0.01) + ($ptf * 0.03) + ($cloaking_level * 0.05) + ($css_level * 0.05) + ($self->body->empire->effective_deception_affinity * 0.03);
    $ship->stealth(sprintf('%.0f', $ship->base_stealth * $improvement ));
    return $ship->stealth;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
