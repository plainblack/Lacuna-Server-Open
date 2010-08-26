package Lacuna::DB::Result::Building::Shipyard;

use Moose;
no warnings qw(uninitialized);
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
    smuggler_ship                 => 'Lacuna::DB::Result::Building::Propulsion',
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
        seconds => 3600,
        waste   => 1000,
    },  
    cargo_ship => {
        food    => 1200,
        water   => 3600,
        energy  => 12000,
        ore     => 20400,
        seconds => 7200,
        waste   => 1500,
    },  
    smuggler_ship => {
        food    => 1500,
        water   => 3900,
        energy  => 27000,
        ore     => 16800,
        seconds => 28800,
        waste   => 1800,
    },  
    mining_platform_ship => {
        food    => 2400,
        water   => 7200,
        energy  => 48000,
        ore     => 40800,
        seconds => 28800,
        waste   => 6600,
    },  
    colony_ship => {
        food    => 100000,
        water   => 100000,
        energy  => 100000,
        ore     => 100000,
        seconds => 43200,
        waste   => 10000,
    },  
    terraforming_platform_ship => {
        food    => 9600,
        water   => 18000,
        energy  => 51000,
        ore     => 42600,
        seconds => 45000,
        waste   => 9000,
    },  
    gas_giant_settlement_platform_ship => {
        food    => 3600,
        water   => 9000,
        energy  => 54000,
        ore     => 45000,
        seconds => 48000,
        waste   => 12300,
    },  
    space_station => {
        food    => 10800,
        water   => 27000,
        energy  => 162000,
        ore     => 350000,
        seconds => 86400,
        waste   => 36900,
    },  
};

sub get_ship_costs {
    my ($self, $type) = @_;
    my $costs = ship_costs->{$type};
    my %final;
    foreach my $cost (keys %{$costs}) {
        if ($cost eq 'seconds') {
            $final{$cost} = sprintf('%0.f', $costs->{$cost} * $self->time_cost_reduction_bonus($self->level * 3));
        }
        else {
            $final{$cost} = sprintf('%0.f', $costs->{$cost} * $self->manufacturing_cost_reduction_bonus);
        }
    }
    return \%final;
}

sub max_ships {
    my ($self) = @_;
    return $self->level;
}

sub can_build_ship {
    my ($self, $type, $costs) = @_;
    $costs ||= $self->get_ship_costs($type);
    if ($type ~~ [qw(gas_giant_settlement_platform_ship space_station terraforming_platform_ship)]) {
        confess [1010, 'Not yet implemented.'];
    }
    if ($self->level < 1) {
        confess [1013, "You can't build a ship if the shipyard isn't complete."];
    }
    my $body = $self->body;
    foreach my $key (keys %{$costs}) {
        next if ($key eq 'seconds' || $key eq 'waste');
        my $cost = $costs->{$key};
        unless ($cost <= $body->type_stored($key)) {
            confess [1011, 'Not enough resources.', $key];
        }
    }
    my $ships_building = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({shipyard_id => $self->id, task=>'Building'})->count;
    if ($ships_building >= $self->max_ships) {
        confess [1013, 'You can only have '.$self->max_ships.' ships in the queue at this shipyard. Upgrade the shipyard to support more ships.']
    }
    my $prereq = ship_prereqs->{$type};
    my $count = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search( { body_id => $self->body_id, class => $prereq, level => {'>=' => 1} } )->count;
    unless ($count) {
        confess [1013, 'You need a '.$prereq->name.' to build this ship.', $prereq];
    }
    my $port = $self->body->spaceport->find_open_dock;
    unless (defined $port) {
        confess [1009, 'You do not have a dock available at the Spaceport.'];
    }
    return $port;
}


sub build_ship {
    my ($self, $port, $type, $time) = @_;
    $time ||= $self->get_ship_costs($type)->{seconds};
    my $latest = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        { shipyard_id => $self->id, task => 'Building' },
        { order_by    => { -desc => 'date_available' }, rows=>1},
        )->single;
    my $date_completed;
    if (defined $latest) {
        $date_completed = $latest->date_available->clone;
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
        spaceport_id    => $port->id,
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

use constant ship_speed => {
    probe                               => 5000,
    gas_giant_settlement_platform_ship  => 700,
    terraforming_platform_ship          => 750,
    mining_platform_ship                => 1000,
    cargo_ship                          => 1500,
    smuggler_ship                       => 2500,
    spy_pod                             => 3000,
    colony_ship                         => 600,
    space_station                       => 5,
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

use constant cargo_ship_base => 950;
use constant smuggler_ship_base => 480;

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
        my $trade_ministry_level = 0;
        my $trade_ministry = $self->trade_ministry;
        if (defined $trade_ministry) {
            $trade_ministry_level = $trade_ministry->level;
        }
        return $self->body->empire->species->trade_affinity * $trade_ministry_level;
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
