package Lacuna::DB::Result::Building::Shipyard;

use Moose;
extends 'Lacuna::DB::Result::Building';
use Lacuna::Util qw(to_seconds format_date);
use DateTime;

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships));
};

use constant ship_prereqs => {
    probe                         => 'Lacuna::DB::Result::Building::Observatory',
    colony_ship                   => 'Lacuna::DB::Result::Building::Observatory',
    spy_pod                       => 'Lacuna::DB::Result::Building::Espionage',
    cargo_ship                    => 'Lacuna::DB::Result::Building::Trade',
    space_station                 => 'Lacuna::DB::Result::Building::Embassy',
    smuggler_ship                 => 'Lacuna::DB::Result::Building::Espionage',
    mining_platform_ship          => 'Lacuna::DB::Result::Building::Ore::Ministry',
    terraforming_platform_ship    => 'Lacuna::DB::Result::Building::TerraformingLab',
    gas_giant_settlement_platform_ship     => 'Lacuna::DB::Result::Building::GasGiantLab',
};

use constant ship_costs => {
    probe => {
        food    => 100,
        water   => 300,
        energy  => 2000,
        ore     => 1700,
        seconds => 3600,
        waste   => 500,
    },  
    spy_pod => {
        food    => 200,
        water   => 600,
        energy  => 4000,
        ore     => 3400,
        seconds => 7200,
        waste   => 1000,
    },  
    cargo_ship => {
        food    => 400,
        water   => 1200,
        energy  => 8000,
        ore     => 6800,
        seconds => 7200,
        waste   => 500,
    },  
    smuggler_ship => {
        food    => 500,
        water   => 1300,
        energy  => 9000,
        ore     => 5600,
        seconds => 9600,
        waste   => 600,
    },  
    mining_platform_ship => {
        food    => 800,
        water   => 2400,
        energy  => 16000,
        ore     => 13600,
        seconds => 9600,
        waste   => 2200,
    },  
    colony_ship => {
        food    => 14000,
        water   => 18000,
        energy  => 16000,
        ore     => 14500,
        seconds => 21600,
        waste   => 4500,
    },  
    terraforming_platform_ship => {
        food    => 3200,
        water   => 6000,
        energy  => 17000,
        ore     => 14200,
        seconds => 15000,
        waste   => 3000,
    },  
    gas_giant_settlement_platform_ship => {
        food    => 1200,
        water   => 3000,
        energy  => 18000,
        ore     => 15000,
        seconds => 16000,
        waste   => 4100,
    },  
    space_station => {
        food    => 3600,
        water   => 9000,
        energy  => 54000,
        ore     => 45000,
        seconds => 48000,
        waste   => 12300,
    },  
};

sub get_ship_costs {
    my ($self, $type) = @_;
    my $costs = ship_costs->{$type};
    foreach my $cost (keys %{$costs}) {
        if ($cost eq 'seconds') {
            $costs->{$cost} = sprintf('%0.f', $costs->{$cost} * $self->time_cost_reduction_bonus($self->level));
        }
        else {
            $costs->{$cost} = sprintf('%0.f', $costs->{$cost} * $self->manufacturing_cost_reduction_bonus);
        }
    }
    return $costs;
}


sub can_build_ship {
    my ($self, $type, $costs) = @_;
    $costs ||= $self->get_ship_costs($type);
    if ($self->level < 1) {
        confess [1013, "You can't build a ship if the shipyard isn't complete."];
    }
    my $body = $self->body;
    foreach my $key (keys %{$costs}) {
        next if ($key eq 'seconds' || $key eq 'waste');
        my $cost = $costs->{$key};
        my $stored = $key.'_stored';
        unless ($cost <= $body->$stored) {
            confess [1011, 'Not enough resources.', $key];
        }
    }
    my $prereq = ship_prereqs->{$type};
    my $count = Lacuna->db->resultset($prereq)->count( where => { body_id => $self->body_id, class => $prereq, level => ['>=', 1] } );
    unless ($count) {
        confess [1013, q{You don't have the prerequisites to build this ship.}, $prereq];
    }
    return 1;
}


sub build_ship {
    my ($self, $type, $time) = @_;
    $time ||= $self->get_ship_costs($type)->{seconds};
    my $latest = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        { shipyard_id => $self->id},
        { order_by    => { -desc => 'date_completed' } },
        )->single;
    my $date_completed;
    if (defined $latest) {
        $date_completed = $latest->date_completed->clone;
    }
    else {
        $date_completed = DateTime->now;
    }
    $date_completed->add(seconds=>$time);
    my $name = $type;
    $name =~ s/(_|^)(\w)(.*?)(?=_|$)/\u$2/sg;
    $name .= $self->level;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({
        shipyard_id     => $self->id,
        date_started    => DateTime->now,
        date_available  => $date_completed,
        task            => 'Building',
        type            => $type,
        name            => $name,
        body_id         => $self->body_id,
        speed           => $self->get_ship_speed($type),
        hold_size       => $self->get_ship_hold_size($type),
    })->insert;
}

before delete => sub {
    my ($self) = @_;
    Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({shipyard_id => $self->id, task => 'building' })->delete_all;
};

use constant controller_class => 'Lacuna::Building::Shipyard';

use constant building_prereq => {'Lacuna::DB::Result::Building::SpacePort'=>1};

use constant image => 'shipyard';

use constant name => 'Shipyard';

use constant food_to_build => 75;

use constant energy_to_build => 75;

use constant ore_to_build => 75;

use constant water_to_build => 75;

use constant waste_to_build => 100;

use constant time_to_build => 300;

use constant food_consumption => 4;

use constant energy_consumption => 6;

use constant ore_consumption => 6;

use constant water_consumption => 4;

use constant waste_production => 2;

use constant star_to_body_distance_ratio => 100;

use constant ship_speed => {
    probe                               => 500,
    gas_giant_settlement_platform_ship  => 70,
    terraforming_platform_ship          => 75,
    mining_platform_ship                => 100,
    cargo_ship                          => 150,
    smuggler_ship                       => 250,
    spy_pod                             => 300,
    colony_ship                         => 50,
    space_station                       => 1,
};


has propulsion_factory => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->body->get_building_of_class('Lacuna::DB::Result::Building::Propulsion');
    },
);

sub get_ship_speed {
    my ($self, $type) = @_;
    my $base_speed = $self->ship_speed->{$type};
    my $propulsion_level = (defined $self->propulsion_factory) ? $self->propulsion_factory->level : 0;
    my $speed_improvement = $propulsion_level * 5 + $self->body->empire->species->science_affinity * 3;
    return sprintf('%.0f', $base_speed * ((100 + $speed_improvement) / 100));
}


# CARGO HOLD SIZE

use constant cargo_ship_base => 2000;
use constant smuggler_ship_base => 1200;

has trade_ministry => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->body->get_building_of_class('Lacuna::DB::Result::Building::Trade');
    },
);

has hold_size_bonus => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return (100 + ($self->body->empire->species->trade_affinity * 25) + ($self->trade_ministry->level * 30)) / 100;
    },
);

sub get_ship_hold_size {
    my ($self, $type) = @_;
    my $base = 0;
    $base = $self->cargo_ship_base if ($type eq 'cargo_ship');
    $base = $self->smuggler_ship_base if ($type eq 'smuggler_ship');
    return sprintf('%.0f', $base * $self->hold_size_bonus);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
