package Lacuna::DB::Building::Shipyard;

use Moose;
extends 'Lacuna::DB::Building';
use Lacuna::Util qw(to_seconds format_date);
use DateTime;

__PACKAGE__->add_attributes(
    ship_builds  => { isa=>'HashRef' },  
);


use constant ship_prereqs => {
    probe                         => 'Lacuna::DB::Building::Observatory',
    colony_ship                   => 'Lacuna::DB::Building::Observatory',
    spy_pod                       => 'Lacuna::DB::Building::Espionage',
    cargo_ship                    => 'Lacuna::DB::Building::Trade',
    space_station                 => 'Lacuna::DB::Building::Embassy',
    smuggler_ship                 => 'Lacuna::DB::Building::Espionage',
    mining_platform_ship          => 'Lacuna::DB::Building::Ore::Ministry',
    terraforming_platform_ship    => 'Lacuna::DB::Building::TerraformingLab',
    gas_giant_settlement_ship     => 'Lacuna::DB::Building::GasGiantLab',
};

use constant ship_costs => {
    probe => {
        food    => 1000,
        water   => 1000,
        energy  => 1000,
        ore     => 1000,
        seconds => 1000,
        waste   => 100,
    },  
    colony_ship => {
        food    => 1000,
        water   => 1000,
        energy  => 1000,
        ore     => 1000,
        seconds => 1000,
        waste   => 100,
    },  
    spy_pod => {
        food    => 1000,
        water   => 1000,
        energy  => 1000,
        ore     => 1000,
        seconds => 1000,
        waste   => 100,
    },  
    cargo_ship => {
        food    => 1000,
        water   => 1000,
        energy  => 1000,
        ore     => 1000,
        seconds => 1000,
        waste   => 100,
    },  
    space_station => {
        food    => 1000,
        water   => 1000,
        energy  => 1000,
        ore     => 1000,
        seconds => 1000,
        waste   => 100,
    },  
    smuggler_ship => {
        food    => 1000,
        water   => 1000,
        energy  => 1000,
        ore     => 1000,
        seconds => 1000,
        waste   => 100,
    },  
    mining_platform_ship => {
        food    => 1000,
        water   => 1000,
        energy  => 1000,
        ore     => 1000,
        seconds => 1000,
        waste   => 100,
    },  
    terraforming_platform_ship => {
        food    => 1000,
        water   => 1000,
        energy  => 1000,
        ore     => 1000,
        seconds => 1000,
        waste   => 100,
    },  
    gas_giant_settlement_ship => {
        food    => 1000,
        water   => 1000,
        energy  => 1000,
        ore     => 1000,
        seconds => 1000,
        waste   => 100,
    },  
};

sub format_ship_builds {
    my $self = shift;
    my $builds = $self->ship_builds;
    $builds->{next_completed} = format_date(DateTime->from_epoch(epoch=>$builds->{next_completed}));
    return $builds;
}

sub spaceports {
    my $self = shift;
    return $self->simpledb->domain('Lacuna::DB::Building::SpacePort')->search(
        where => { body_id => $self->body_id, class => 'Lacuna::DB::Building::SpacePort' }
        );
}

sub get_ship_costs {
    my ($self, $type) = @_;
    my $costs = ship_costs->{$type};
    my $species = $self->empire->species;
    my $manufacturing_affinity = $species->manufacturing_affinity;
    foreach my $cost (keys %{$costs}) {
        if ($cost eq 'time') {
            $costs->{$cost} = sprintf('%0.f', $costs->{$cost} * $self->time_cost_reduction_bonus($self->level));
        }
        else {
            $costs->{$cost} = sprintf('%0.f', $costs->{$cost} * $self->manufacturing_cost_reduction_bonus);
        }
    }
    return $costs;
}


sub can_build_ship {
    my ($self, $type, $quantity, $costs) = @_;
    $quantity ||= 1;
    $costs ||= $self->get_ship_costs($type);
    if ($self->level < 1) {
        confess [1013, "You can't build a ship if the shipyard isn't built."];
    }
    my $body = $self->body;
    foreach my $key (keys %{$costs}) {
        next if ($key eq 'seconds' || $key eq 'waste');
        my $cost = $costs->{$key} * $quantity;
        my $stored = $key.'_stored';
        unless ($cost <= $body->$stored) {
            confess [1011, 'Not enough resources.', $key];
        }
    }
    my $prereq = ship_prereqs->{$type};
    my $count = $self->simpledb->domain($prereq)->count( where => { body_id => $self->body_id, class => $prereq, level => ['>=', 1] } );
    unless ($count) {
        confess [1013, q{You don't have the prerequisites to build this ship.}, $prereq];
    }
    return 1;
}


sub build_ship {
    my ($self, $type, $quantity, $costs) = @_;
    $quantity ||= 1;
    $costs ||= $self->get_ship_costs($type, $quantity);
    my $body = $self->body;
    foreach my $key (keys %{ $costs }) {
        next if $key eq 'seconds';
        if ($key eq 'waste') {
            $body->add_waste($costs->{waste});
        }
        else {
            my $spend = 'spend_'.$key;
            $body->$spend($costs->{$key} * $quantity);
        }
    }
    $body->put;
    my $builds = $self->ship_builds->{queue};
    push @{$builds->{queue}}, {
        type            => $type,
        seconds_each    => $costs->{seconds},
        quantity        => $quantity,
    };
    unless (exists $builds->{next_completed}) {
        $builds->{next_completed} = DateTime->now->add(seconds => $costs->{seconds})->epoch;
    }
    $self->ship_builds($builds);
    $self->put;
}

sub check_for_completed_ships {
    my ($self, $caller_spaceport) = @_;
    my $builds = $self->ship_builds;
    my $now = DateTime->now;
    my $date_completed = DateTime->from_epoch(epoch=>$builds->{next_completed});
    if ($now > $date_completed) {
        my $difference = to_seconds($now - $date_completed);
        delete $builds->{next_completed};
        my $spaceports = $self->spaceports;
        my $spaceport = $spaceports->next;
        if (defined $caller_spaceport && $caller_spaceport->id eq $spaceport->id) {
            $spaceport = $caller_spaceport;   
        }
        SHIP: while (1) { # keep building ships while we have time
            my $completed_ship = shift @{$builds->{queue}};
            PORT: while (1) {
                if ($spaceport->has_room) { # there's room, so let's add it
                    $spaceport->add_ship($completed_ship->{type});
                }
                else { # we need ourselves a new space port, this one's full
                    $spaceport->put;
                    $spaceport = $spaceports->next;
                    unless (defined $spaceport) { # this ship's gonna go kablooey cuz no spaceports have any room
                        return $self->empire->send_predefined_message(
                            filename    => 'ship_blew_up_at_port.txt',
                            params      => [$completed_ship->{type}, $self->body->name],
                        );
                        last SHIP;
                    }
                    if (defined $caller_spaceport && $caller_spaceport->id eq $spaceport->id) {
                        $spaceport = $caller_spaceport;   
                    }
                    last PORT;
                }
            }
            last SHIP unless (scalar @{$builds->{queue}}); # end, we have no more ships in queue
            my $time_for_next_ship = $builds->{queue}[0];
            if ($time_for_next_ship > $difference) { # end, still time left on next ship
                $builds->{next_completed} = DateTime->now->add(seconds=> ($time_for_next_ship - $difference))->epoch;
                last SHIP;
            }
            else { # whew, another ship completed!
                $difference -= $time_for_next_ship;
            }
        }
        $spaceport->put;
        $self->put;
    }
}


use constant controller_class => 'Lacuna::Building::Shipyard';

use constant building_prereq => {'Lacuna::DB::Building::SpacePort'=>1};

use constant image => 'shipyard';

use constant name => 'Shipyard';

use constant food_to_build => 150;

use constant energy_to_build => 150;

use constant ore_to_build => 150;

use constant water_to_build => 100;

use constant waste_to_build => 100;

use constant time_to_build => 1200;

use constant food_consumption => 5;

use constant energy_consumption => 10;

use constant ore_consumption => 5;

use constant water_consumption => 7;

use constant waste_production => 2;




no Moose;
__PACKAGE__->meta->make_immutable;
