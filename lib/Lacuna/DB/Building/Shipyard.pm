package Lacuna::DB::Building::Shipyard;

use Moose;
extends 'Lacuna::DB::Building';
use Lacuna::Util qw(to_seconds format_date);
use DateTime;

__PACKAGE__->add_attributes(
    ship_builds  => { isa=>'HashRef' },  
);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships));
};

use constant ship_prereqs => {
    probe                         => 'Lacuna::DB::Building::Observatory',
    colony_ship                   => 'Lacuna::DB::Building::Observatory',
    spy_pod                       => 'Lacuna::DB::Building::Espionage',
    cargo_ship                    => 'Lacuna::DB::Building::Trade',
    space_station                 => 'Lacuna::DB::Building::Embassy',
    smuggler_ship                 => 'Lacuna::DB::Building::Espionage',
    mining_platform_ship          => 'Lacuna::DB::Building::Ore::Ministry',
    terraforming_platform_ship    => 'Lacuna::DB::Building::TerraformingLab',
    gas_giant_settlement_platform_ship     => 'Lacuna::DB::Building::GasGiantLab',
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

sub format_ship_builds {
    my $self = shift;
    my $builds = $self->ship_builds;
    return {} unless $builds->{next_completed};
    $builds->{next_completed} = format_date(DateTime->from_epoch(epoch=>$builds->{next_completed}));
    return $builds;
}

sub spaceports {
    my $self = shift;
    return $self->body->get_buildings_of_class('Lacuna::DB::Building::SpacePort');
}

sub get_ship_costs {
    my ($self, $type) = @_;
    my $costs = ship_costs->{$type};
    my $species = $self->empire->species;
    my $manufacturing_affinity = $species->manufacturing_affinity;
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
    my ($self, $type, $quantity, $costs) = @_;
    $quantity ||= 1;
    $costs ||= $self->get_ship_costs($type);
    if ($self->level < 1) {
        confess [1013, "You can't build a ship if the shipyard isn't complete."];
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
    my ($self, $type, $quantity, $time) = @_;
    $quantity ||= 1;
    $time ||= $self->get_ship_costs($type)->{seconds};
    my $builds = $self->ship_builds;
    push @{$builds->{queue}}, {
        type            => $type,
        seconds_each    => $time,
        quantity        => $quantity,
    };
    unless (exists $builds->{next_completed}) {
        $builds->{next_completed} = DateTime->now->add(seconds => $time)->epoch;
    }
    $self->ship_builds($builds);
    $self->put;
}


sub get_next_completed {
    my $self = shift;
    my $builds = $self->ship_builds;
    
    # no ships in queue
    return undef unless exists $builds->{next_completed};
    
    # there are ships in the queue
    my $now = DateTime->now;
    my $completed_date = DateTime->from_epoch(epoch=>$builds->{next_completed});

    # check if any are completed
    unless ($completed_date < $now) {
        return undef;
    }

    # get the next completed ship
    my $next_ship;
    if ($builds->{queue}[0]{quantity} == 1) {
        $next_ship = shift @{$builds->{queue}};
    }
    else {
        $next_ship = $builds->{queue}[0];
        $builds->{queue}[0]{quantity}--;
    }

    # reset next completed date
    if (scalar @{$builds->{queue}}) {
        my $time_for_next_ship = $builds->{queue}[0]{seconds_each};
        $builds->{next_completed} = $completed_date->clone->add(seconds=> $time_for_next_ship)->epoch;
    }
    else {
        delete $builds->{next_completed};
    }
    $self->ship_builds($builds);
    
    return $next_ship;
}

sub check_for_completed_ships {
    my ($self, $caller_spaceport) = @_;
    my $spaceports = $self->spaceports;
    my $spaceport;
    my $spaceport_changed = 0;
    my $shipyard_changed = 0;
    
    # keep building ships while we have time
    SHIP: while (my $completed_ship = $self->get_next_completed) {
        $shipyard_changed = 1;
        
        # find a port to put the space ship, we don't invert this to save a db call
        PORT: while (1) {
            
            # first time running, haven't fetched spaceport yet, so let's get one
            $spaceport = $spaceports->next unless (defined $spaceport);

            # always want to use the preloaded caller spaceport if possible to avoid staleness
            if (defined $caller_spaceport && $caller_spaceport->id eq $spaceport->id) {
                $spaceport = $caller_spaceport;   
            }
            
            # there's room, so let's add a ship
            if (!$spaceport->is_full) { 
                $spaceport->add_ship($completed_ship->{type});
                $spaceport_changed = 1;
                last PORT;
            }
            
            # we need ourselves a new space port, this one's full
            else { 
                $spaceport->put if ($spaceport_changed); # save the current one
                $spaceport_changed = 0;
                $spaceport = $spaceports->next; # get a new one
                
                # this ship's gonna go kablooey cuz no room at any port
                unless (defined $spaceport) {
                    my $type = $completed_ship->{type};
                    $type =~ s/_/ /g;
                    $self->empire->send_predefined_message(
                        tags        => ['Alert'],
                        filename    => 'ship_blew_up_at_port.txt',
                        params      => [$completed_ship->{type}, $self->body->name],
                    );
                    $self->body->add_news(100,'%s was rocked today as a %s exploded at the space port.', $self->body->name, $type);
                    last SHIP;
                }
            }
        }
    }
    
    # save changes
    $spaceport->put if ($spaceport_changed);
    $self->put if ($shipyard_changed);
}

use constant controller_class => 'Lacuna::Building::Shipyard';

use constant building_prereq => {'Lacuna::DB::Building::SpacePort'=>1};

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




no Moose;
__PACKAGE__->meta->make_immutable;
