package Lacuna::DB::Body::Planet;

use Moose;
extends 'Lacuna::DB::Body';
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use List::Util qw(shuffle);
use Lacuna::Util qw(to_seconds);
no warnings 'uninitialized';

__PACKAGE__->add_attributes(
    size                            => { isa => 'Int' },
    empire_id                       => { isa => 'Str', default=>'None' },
    last_tick                       => { isa => 'DateTime'},
    building_count                  => { isa => 'Int', default=>0 },
    happiness_hour                  => { isa => 'Int', default=>0 },
    happiness                       => { isa => 'Int', default=>0 },
    waste_hour                      => { isa => 'Int', default=>0 },
    waste_stored                    => { isa => 'Int', default=>0 },
    waste_capacity                  => { isa => 'Int', default=>0 },
    energy_hour                     => { isa => 'Int', default=>0 },
    energy_stored                   => { isa => 'Int', default=>0 },
    energy_capacity                 => { isa => 'Int', default=>0 },
    water_hour                      => { isa => 'Int', default=>0 },
    water_stored                    => { isa => 'Int', default=>0 },
    water_capacity                  => { isa => 'Int', default=>0 },
    ore_capacity                    => { isa => 'Int', default=>0 },
    rutile_stored                   => { isa => 'Int', default=>0 },
    chromite_stored                 => { isa => 'Int', default=>0 },
    chalcopyrite_stored             => { isa => 'Int', default=>0 },
    galena_stored                   => { isa => 'Int', default=>0 },
    gold_stored                     => { isa => 'Int', default=>0 },
    uraninite_stored                => { isa => 'Int', default=>0 },
    bauxite_stored                  => { isa => 'Int', default=>0 },
    goethite_stored                 => { isa => 'Int', default=>0 },
    halite_stored                   => { isa => 'Int', default=>0 },
    gypsum_stored                   => { isa => 'Int', default=>0 },
    trona_stored                    => { isa => 'Int', default=>0 },
    kerogen_stored                  => { isa => 'Int', default=>0 },
    methane_stored                  => { isa => 'Int', default=>0 },
    anthracite_stored               => { isa => 'Int', default=>0 },
    sulfur_stored                   => { isa => 'Int', default=>0 },
    zircon_stored                   => { isa => 'Int', default=>0 },
    monazite_stored                 => { isa => 'Int', default=>0 },
    fluorite_stored                 => { isa => 'Int', default=>0 },
    beryl_stored                    => { isa => 'Int', default=>0 },
    magnetite_stored                => { isa => 'Int', default=>0 },
    ore_hour                        => { isa => 'Int', default=>0 },
    food_capacity                   => { isa => 'Int', default=>0 },
    food_consumption_hour           => { isa => 'Int', default=>0 },
    lapis_production_hour           => { isa => 'Int', default=>0 },
    potato_production_hour          => { isa => 'Int', default=>0 },
    apple_production_hour           => { isa => 'Int', default=>0 },
    root_production_hour            => { isa => 'Int', default=>0 },
    corn_production_hour            => { isa => 'Int', default=>0 },
    cider_production_hour           => { isa => 'Int', default=>0 },
    wheat_production_hour           => { isa => 'Int', default=>0 },
    bread_production_hour           => { isa => 'Int', default=>0 },
    soup_production_hour            => { isa => 'Int', default=>0 },
    chip_production_hour            => { isa => 'Int', default=>0 },
    pie_production_hour             => { isa => 'Int', default=>0 },
    pancake_production_hour         => { isa => 'Int', default=>0 },
    milk_production_hour            => { isa => 'Int', default=>0 },
    meal_production_hour            => { isa => 'Int', default=>0 },
    algae_production_hour           => { isa => 'Int', default=>0 },
    syrup_production_hour           => { isa => 'Int', default=>0 },
    fungus_production_hour          => { isa => 'Int', default=>0 },
    burger_production_hour          => { isa => 'Int', default=>0 },
    shake_production_hour           => { isa => 'Int', default=>0 },
    beetle_production_hour          => { isa => 'Int', default=>0 },
    lapis_stored                    => { isa => 'Int', default=>0 },
    potato_stored                   => { isa => 'Int', default=>0 },
    apple_stored                    => { isa => 'Int', default=>0 },
    root_stored                     => { isa => 'Int', default=>0 },
    corn_stored                     => { isa => 'Int', default=>0 },
    cider_stored                    => { isa => 'Int', default=>0 },
    wheat_stored                    => { isa => 'Int', default=>0 },
    bread_stored                    => { isa => 'Int', default=>0 },
    soup_stored                     => { isa => 'Int', default=>0 },
    chip_stored                     => { isa => 'Int', default=>0 },
    pie_stored                      => { isa => 'Int', default=>0 },
    pancake_stored                  => { isa => 'Int', default=>0 },
    milk_stored                     => { isa => 'Int', default=>0 },
    meal_stored                     => { isa => 'Int', default=>0 },
    algae_stored                    => { isa => 'Int', default=>0 },
    syrup_stored                    => { isa => 'Int', default=>0 },
    fungus_stored                   => { isa => 'Int', default=>0 },
    burger_stored                   => { isa => 'Int', default=>0 },
    shake_stored                    => { isa => 'Int', default=>0 },
    beetle_stored                   => { isa => 'Int', default=>0 },
    freebies                        => { isa => 'HashRef' },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');
__PACKAGE__->has_many('regular_buildings','Lacuna::DB::Building','body_id', mate => 'body');
__PACKAGE__->has_many('food_buildings','Lacuna::DB::Building::Food','body_id', mate => 'body');
__PACKAGE__->has_many('water_buildings','Lacuna::DB::Building::Water','body_id', mate => 'body');
__PACKAGE__->has_many('waste_buildings','Lacuna::DB::Building::Waste','body_id', mate => 'body');
__PACKAGE__->has_many('ore_buildings','Lacuna::DB::Building::Ore','body_id', mate => 'body');
__PACKAGE__->has_many('energy_buildings','Lacuna::DB::Building::Energy','body_id', mate => 'body');
__PACKAGE__->has_many('permanent_buildings','Lacuna::DB::Building::Permanent','body_id', mate => 'body');

sub get_free_upgrade {
    my ($self, $class) = @_;
    return $self->freebies->{upgrades}{$class} || 0;
}

sub add_free_upgrade {
    my ($self, $class, $level) = @_;
    my $freebies = $self->freebies;
    $freebies->{upgrades}{$class} = $level;
    $self->freebies($freebies);
    return $self;
}

sub spend_free_upgrade {
    my ($self, $class) = @_;
    my $freebies = $self->freebies;
    delete $freebies->{upgrades}{$class};
    $self->freebies($freebies);
    return $self;
}

sub get_free_build {
    my ($self, $class) = @_;
    return $self->freebies->{builds}{$class} || 0;
}

sub add_free_build {
    my ($self, $class, $level) = @_;
    my $freebies = $self->freebies;
    $freebies->{builds}{$class} = $level;
    $self->freebies($freebies);
    return $self;
}

sub spend_free_build {
    my ($self, $class) = @_;
    my $freebies = $self->freebies;
    delete $freebies->{builds}{$class};
    $self->freebies($freebies);
    return $self;
}

sub builds { 
    my ($self, $where, $reverse) = @_;
    my $order = 'date_complete';
    if ($reverse) {
        $order = [$order];
    }
    $where->{body_id} = $self->id;
    $where->{date_complete} = ['>',DateTime->now->subtract(years=>100)] unless exists $where->{date_complete};
    return $self->simpledb->domain('Lacuna::DB::BuildQueue')->search(
        where       => $where,
        order_by    => $order,
        consistent  => 1,
        set         => {
            body  => $self,
        },
    );
}

sub ships_travelling { 
    my ($self, $where, $reverse) = @_;
    my $order = 'date_arrives';
    if ($reverse) {
        $order = [$order];
    }
    $where->{body_id} = $self->id;
    $where->{date_arrives} = ['>',DateTime->now->subtract(years=>100)] unless exists $where->{date_arrives};
    return $self->simpledb->domain('Lacuna::DB::TravelQueue')->search(
        where       => $where,
        order_by    => $order,
        consistent  => 1,
        set         => {
            body    => $self,
        },
    );
}

sub sanitize {
    my ($self) = @_;
    foreach my $type (qw(food regular water waste ore energy)) {
        my $method = $type.'_buildings';
        $self->$method->delete;
    }
    my @attributes = qw(    building_count happiness_hour happiness waste_hour waste_stored waste_capacity
        energy_hour energy_stored energy_capacity water_hour water_stored water_capacity ore_capacity
        rutile_stored chromite_stored chalcopyrite_stored galena_stored gold_stored uraninite_stored bauxite_stored
        goethite_stored halite_stored gypsum_stored trona_stored kerogen_stored methane_stored anthracite_stored
        sulfur_stored zircon_stored monazite_stored fluorite_stored beryl_stored magnetite_stored ore_hour
        food_capacity food_consumption_hour lapis_production_hour potato_production_hour apple_production_hour
        root_production_hour corn_production_hour cider_production_hour wheat_production_hour bread_production_hour
        soup_production_hour chip_production_hour pie_production_hour pancake_production_hour milk_production_hour
        meal_production_hour algae_production_hour syrup_production_hour fungus_production_hour burger_production_hour
        shake_production_hour beetle_production_hour lapis_stored potato_stored apple_stored root_stored corn_stored
        cider_stored wheat_stored bread_stored soup_stored chip_stored pie_stored pancake_stored milk_stored meal_stored
        algae_stored syrup_stored fungus_stored burger_stored shake_stored beetle_stored 
    );
    $self->ships_travelling->delete;
    $self->simpledb->domain('travel_queue')->search(where=>{foreign_body_id => $self->id})->delete;
    foreach my $attribute (@attributes) {
        $self->$attribute(0);
    }
    $self->empire_id('None');
    if ($self->get_type eq 'habitable planet') {
        $self->usable_as_starter(rand(99999));
    }
    $self->put;
}

around 'get_status' => sub {
    my ($orig, $self, $empire) = @_;
    my $out = $orig->($self);
    my %ore;
    foreach my $type (ORE_TYPES) {
        $ore{$type} = $self->$type();
    }
    $out->{size}            = $self->size;
    $out->{ore}             = \%ore;
    $out->{water}           = $self->water;
    if (defined $empire) {
        if ($self->empire_id eq $empire->id) {
            $out->{alignment} = 'self';
        }
        elsif ($self->empire_id ne 'None') {
            $out->{alignment} = 'hostile';
        }
    }
    if (defined $empire && $empire->id eq $self->empire_id) {
        $self->tick;
        $out->{building_count}  = $self->building_count;
        $out->{water_capacity}  = $self->water_capacity;
        $out->{water_stored}    = $self->water_stored;
        $out->{water_hour}      = $self->water_hour;
        $out->{energy_capacity} = $self->energy_capacity;
        $out->{energy_stored}   = $self->energy_stored;
        $out->{energy_hour}     = $self->energy_hour;
        $out->{food_capacity}   = $self->food_capacity;
        $out->{food_stored}     = $self->food_stored;
        $out->{food_hour}       = $self->food_hour;
        $out->{ore_capacity}    = $self->ore_capacity;
        $out->{ore_stored}      = $self->ore_stored;
        $out->{ore_hour}        = $self->ore_hour;
        $out->{waste_capacity}  = $self->waste_capacity;
        $out->{waste_stored}    = $self->waste_stored;
        $out->{waste_hour}      = $self->waste_hour;
        $out->{happiness}       = $self->happiness;
        $out->{happiness_hour}  = $self->happiness_hour;
    }
    return $out;
};

# resource concentrations
use constant rutile => 1;

use constant chromite => 1;

use constant chalcopyrite => 1;

use constant galena => 1;

use constant gold => 1;

use constant uraninite => 1;

use constant bauxite => 1;

use constant goethite => 1;

use constant halite => 1;

use constant gypsum => 1;

use constant trona => 1;

use constant kerogen => 1;

use constant methane => 1;

use constant anthracite => 1;

use constant sulfur => 1;

use constant zircon => 1;

use constant monazite => 1;

use constant fluorite => 1;

use constant beryl => 1;

use constant magnetite => 1;

use constant water => 0;

sub rutile_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->rutile * $self->ore_hour / 10000);
}
 
sub chromite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->chromite * $self->ore_hour / 10000);
}

sub chalcopyrite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->chalcopyrite * $self->ore_hour / 10000);
}

sub galena_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->galena * $self->ore_hour / 10000);
}

sub gold_hour {
    my ($self) = @_;
    return sprintf('%.0f', $self->gold * $self->ore_hour / 10000);
}

sub uraninite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->uraninite * $self->ore_hour / 10000);
}

sub bauxite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->bauxite * $self->ore_hour / 10000);
}

sub goethite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->goethite * $self->ore_hour / 10000);
}

sub halite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->halite * $self->ore_hour / 10000);
}

sub gypsum_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->gypsum * $self->ore_hour / 10000);
}

sub trona_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->trona * $self->ore_hour / 10000);
}

sub kerogen_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->kerogen * $self->ore_hour / 10000);
}

sub methane_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->methane * $self->ore_hour / 10000);
}

sub anthracite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->anthracite * $self->ore_hour / 10000);
}

sub sulfur_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->sulfur * $self->ore_hour / 10000);
}

sub zircon_hour {
    my ($self) = @_;
    return sprintf('%.0f', $self->zircon * $self->ore_hour / 10000);
}

sub monazite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->monazite * $self->ore_hour / 10000);
}

sub fluorite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->fluorite * $self->ore_hour / 10000);
}

sub beryl_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->beryl * $self->ore_hour / 10000);
}

sub magnetite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->magnetite * $self->ore_hour / 10000);
}

# BUILDINGS

sub get_buildings_of_class {
    my ($self, $class) = @_;
    return $self->simpledb->domain($class)->search(
        where       => {
            body_id => $self->id,
            class   => $class,
            level   => ['>=', 0],
        },
        order_by    => ['level'],
        set         => {
            body    => $self,
            empire  => $self->empire,
        },
    );
}

has command => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get_buildings_of_class('Lacuna::DB::Building::PlanetaryCommand')->next;
    },
);

has refinery => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get_buildings_of_class('Lacuna::DB::Building::Ore::Refinery')->next;
    },
);

sub buildings {
    my $self = shift;
    my $buildings = sub {
        my $class = shift;
        return $self->simpledb->domain($class)->search(
		where	=> { body_id => $self->id },
		set	=> { body => $self, empire => $self->empire },
	);
    };
    return (
	$buildings->('Lacuna::DB::Building'),
        $buildings->('Lacuna::DB::Building::Food'),
        $buildings->('Lacuna::DB::Building::Water'),
        $buildings->('Lacuna::DB::Building::Waste'),
        $buildings->('Lacuna::DB::Building::Ore'),
        $buildings->('Lacuna::DB::Building::Energy'),
        $buildings->('Lacuna::DB::Building::Permanent'),
        );
}

sub is_space_free {
    my ($self, $x, $y) = @_;
    my $db = $self->simpledb;
    foreach my $domain (qw(building energy water food waste ore permanent)) {
        my $count = $db->domain($domain)->count(
            where => {
                body_id => $self->id,
                x       => $x,
                y       => $y,
            },
            consistent => 1, # prevents stacking attack
        );
        return 0 if $count > 0;
    }
    return 1;
}

sub check_for_available_build_space {
    my ($self, $x, $y) = @_;
    if ($x > 5 || $x < -5 || $y > 5 || $y < -5) {
        confess [1009, "That's not a valid space for a building.", [$x, $y]];
    }
    if ($self->building_count >= $self->size) {
        confess [1009, "You've already reached the maximum number of buildings for this planet.", $self->size];
    }
    unless ($self->is_space_free($x, $y)) {
        confess [1009, "That space is already occupied.", [$x,$y]]; 
    }
    return 1;
}

sub has_met_building_prereqs {
    my ($self, $building) = @_;
    $building->check_build_prereqs($self);
    $self->has_resources_to_build($building);
    $self->has_resources_to_operate($building);
    $self->has_max_instances_of_building($building);
    return 1;
}

sub can_build_building {
    my ($self, $building) = @_;
    $self->check_for_available_build_space($building->x, $building->y);
    $self->tick;
    $self->has_room_in_build_queue;
    $self->has_met_building_prereqs($building);
    return $self;
}

sub has_room_in_build_queue {
    my ($self) = shift;
    my $max = 1;
    my $dev_ministry = $self->simpledb->domain('Lacuna::DB::Building::Development')->search(
        where   => {
            body_id => $self->id,
            class   => 'Lacuna::DB::Building::Development'
        }
        )->next;
    if (defined $dev_ministry) {
        $max += $dev_ministry->level;
    }
    my $count = $self->simpledb->domain('build_queue')->count(where=>{body_id=>$self->id});
    if ($count >= $max) {
        confess [1009, "There's no room left in the build queue.", $max];
    }
    return 1; 
}

sub has_resources_to_operate {
    my ($self, $building) = @_;
    my $after = $building->stats_after_upgrade;
    foreach my $resource (qw(food energy ore water waste)) {
        my $method = $resource.'_hour';
        # don't allow it if it sucks resources && its sucking more than we're producing
        if ($after->{$method} < 0 && $self->$method - $building->$method + $after->{$method} < 0) {
            confess [1012, "Unsustainable. Not enough resources being produced to build this.", $resource];
        }
    }
    return 1;
}

sub get_existing_build_queue_time {
    my $self = shift;
    my $time_to_build = DateTime->now;
    my $last_in_queue = $self->builds(undef, 1)->next;
    if (defined $last_in_queue) {
        $time_to_build = $last_in_queue->date_complete;    
    }
    return $time_to_build;
}
    
sub build_building {
    my ($self, $building) = @_;
    
    $self->building_count($self->building_count + 1);
    $self->put;
    
    # set time to build, plus what's in the queue
    my $time_to_build = $self->get_existing_build_queue_time->add(seconds=>$building->time_to_build);
    
    # add to build queue
    my $queue = $self->simpledb->domain('build_queue')->insert({
        date_created        => DateTime->now,
        date_complete       => $time_to_build,
        building_id         => $building->id,
        empire_id           => $self->empire_id,
        building_class      => $building->class,
        body_id             => $self->id,
    });

    # add building placeholder to planet
    $building->build_queue_id($queue->id);
    $building->put;

    $self->empire->trigger_full_update;
}

sub found_colony {
    my ($self, $empire) = @_;
    $self->empire_id($empire->id);
    $self->usable_as_starter('No');
    $self->last_tick(DateTime->now);
    $self->put;    

    # award medal
    my $type = ref $self;
    $type =~ s/^.*::(\w\d+)$/$1/;
    $empire->add_medal($type);

    # add command building
    my $command = Lacuna::DB::Building::PlanetaryCommand->new(
        simpledb        => $self->simpledb,
        x               => 0,
        y               => 0,
        class           => 'Lacuna::DB::Building::PlanetaryCommand',
        date_created    => DateTime->now,
        body_id         => $self->id,
        body            => $self,
        empire_id       => $empire->id,
        empire          => $empire,
        level           => $empire->species->growth_affinity - 1,
    );
    $self->build_building($command);
    $command->finish_upgrade;
    
    # add starting resources
    $self->add_algae(700);
    $self->add_energy(700);
    $self->add_water(700);
    $self->add_ore(700);
    $self->put;
        
    return $self;
}

sub has_resources_to_build {
    my ($self, $building, $cost) = @_;
    $cost ||= $building->cost_to_upgrade;
    foreach my $resource (qw(food energy ore water)) {
        my $stored = $resource.'_stored';
        unless ($self->$stored >= $cost->{$resource}) {
            confess [1011, "Not enough resources in storage to build this.", $resource];
        }
    }
    return 1;
}

sub has_max_instances_of_building {
    my ($self, $building) = @_;
    return 0 if $building->max_instances_per_planet == 9999999;
    my $count = $self->simpledb->domain($building->class)->count(where=>{body_id=>$self->id, class=>$building->class});
    return ($building->max_instances_per_planet > $count) ? 1 : 0;
}

sub recalc_stats {
    my ($self) = @_;
    my %stats;
    foreach my $buildings ($self->buildings) {
        while (my $building = $buildings->next) {
            $stats{waste_capacity} += $building->waste_capacity;
            $stats{water_capacity} += $building->water_capacity;
            $stats{energy_capacity} += $building->energy_capacity;
            $stats{food_capacity} += $building->food_capacity;
            $stats{ore_capacity} += $building->ore_capacity;
            $stats{happiness_hour} += $building->happiness_hour;
            $stats{waste_hour} += $building->waste_hour;               
            $stats{energy_hour} += $building->energy_hour;
            $stats{water_hour} += $building->water_hour;
            $stats{ore_hour} += $building->ore_hour;
            $stats{food_consumption_hour} += $building->food_consumption_hour;
            foreach my $type (FOOD_TYPES) {
                my $method = $type.'_production_hour';
                $stats{$method} += $building->$method();
            }
         }
    }
    $self->update(\%stats);
    $self->put;
    return $self;
} 

# RESOURCE MANGEMENT

sub tick {
    my ($self) = @_;
    my $now = DateTime->now;
    my $builds = $self->builds({date_complete => ['<=', $now]});
    my $ships_travelling = $self->ships_travelling({date_arrives => ['<=', $now]});
    my $ship = $ships_travelling->next;
    my $build = $builds->next;
    
    # deal with events that may have occurred
    while (1) {
        if (defined $ship && defined $build ) {
            if ( $ship->date_arrives > $build->date_complete ) {
                $self->tick_to($build->date_complete);
                $build->finish_build;
                $build = $builds->next;
            }
            else {
                $self->tick_to($ship->date_arrives);
                $ship->arrive;
                $ship = $ships_travelling->next; 
            }
        }
        elsif (defined $build) {
            $self->tick_to($build->date_complete);
            $build->finish_build;
            $build = $builds->next;
        }
        elsif (defined $ship) {
            $self->tick_to($ship->date_arrives);
            $ship->arrive;
            $ship = $ships_travelling->next; 
        }
        else {
            last;
        }
    }
    $self->tick_to($now);
}

sub tick_to {
    my ($self, $now) = @_;
    my $interval = $now - $self->last_tick;
    my $seconds = to_seconds($interval);
    my $tick_rate = $seconds / 3600;
    $self->last_tick($now);
    $self->add_happiness(sprintf('%.0f', $self->happiness_hour * $tick_rate));
    $self->add_waste(sprintf('%.0f', $self->waste_hour * $tick_rate));
    $self->add_energy(sprintf('%.0f', $self->energy_hour * $tick_rate));
    $self->add_water(sprintf('%.0f', $self->water_hour * $tick_rate));
    foreach my $type (ORE_TYPES) {
        my $hour_method = $type.'_hour';
        my $add_method = 'add_'.$type;
        $self->$add_method(sprintf('%.0f', $self->$hour_method() * $tick_rate));
    }
    my $food_consumed = sprintf('%.0f', $self->food_consumption_hour * $tick_rate);
    foreach my $type (shuffle FOOD_TYPES) {
        my $hour_method = $type.'_production_hour';
        my $add_method = 'add_'.$type;
        my $food_produced = sprintf('%.0f', $self->$hour_method() * $tick_rate);
        if ($food_produced > $food_consumed) {
            $food_produced -= $food_consumed;
            $food_consumed = 0;
            $self->$add_method($food_produced);
        }
        else {
            $food_consumed -= $food_produced;
        }
    }
    $self->put;
}

sub food_hour {
    my ($self) = @_;
    my $tally = 0;
    foreach my $food (FOOD_TYPES) {
        my $method = $food."_production_hour";
        $tally += $self->$method;
    }
    $tally -= $self->food_consumption_hour;
    return $tally;
}

sub food_stored {
    my ($self) = @_;
    my $tally = 0;
    foreach my $food (FOOD_TYPES) {
        my $method = $food."_stored";
        $tally += $self->$method;
    }
    return $tally;
}

sub ore_stored {
    my ($self) = @_;
    my $tally = 0;
    foreach my $ore (ORE_TYPES) {
        my $method = $ore."_stored";
        $tally += $self->$method;
    }
    return $tally;
}

sub add_ore {
    my ($self, $value) = @_;
    foreach my $type (shuffle ORE_TYPES) {
        next unless $self->$type >= 100; 
        my $add_method = 'add_'.$type;
        $self->$add_method($value);
        last;
    }
}

sub add_magnetite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->magnetite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->magnetite_stored;
    $self->magnetite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_beryl {
    my ($self, $value) = @_;
    my $amount_to_store = $self->beryl_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->beryl_stored;
    $self->beryl_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_fluorite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->fluorite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->fluorite_stored;
    $self->fluorite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_monazite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->monazite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->monazite_stored;
    $self->monazite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_zircon {
    my ($self, $value) = @_;
    my $amount_to_store = $self->zircon_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->zircon_stored;
    $self->zircon_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_sulfur {
    my ($self, $value) = @_;
    my $amount_to_store = $self->sulfur_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->sulfur_stored;
    $self->sulfur_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_anthracite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->anthracite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->anthracite_stored;
    $self->anthracite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_methane {
    my ($self, $value) = @_;
    my $amount_to_store = $self->methane_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->methane_stored;
    $self->methane_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_kerogen {
    my ($self, $value) = @_;
    my $amount_to_store = $self->kerogen_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->kerogen_stored;
    $self->kerogen_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_trona {
    my ($self, $value) = @_;
    my $amount_to_store = $self->trona_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->trona_stored;
    $self->trona_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_gypsum {
    my ($self, $value) = @_;
    my $amount_to_store = $self->gypsum_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->gypsum_stored;
    $self->gypsum_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_halite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->halite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->halite_stored;
    $self->halite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_goethite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->goethite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->goethite_stored;
    $self->goethite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_bauxite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->bauxite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->bauxite_stored;
    $self->bauxite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_uraninite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->uraninite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->uraninite_stored;
    $self->uraninite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_gold {
    my ($self, $value) = @_;
    my $amount_to_store = $self->gold_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->gold_stored;
    $self->gold_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_galena {
    my ($self, $value) = @_;
    my $amount_to_store = $self->galena_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->galena_stored;
    $self->galena_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_chalcopyrite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->chalcopyrite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->chalcopyrite_stored;
    $self->chalcopyrite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_chromite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->chromite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->chromite_stored;
    $self->chromite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_rutile {
    my ($self, $value) = @_;
    my $amount_to_store = $self->rutile_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->rutile_stored;
    $self->rutile_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub spend_ore {
    my ($self, $value) = @_;
    foreach my $type (shuffle ORE_TYPES) {
        my $method = $type."_stored";
        my $stored = $self->$method;
        if ($stored > $value) {
            $self->$method($stored - $value);
            last;
        }
        else {
            $value -= $stored;
            $self->$method(0);
        }
    }
}

sub add_beetle {
    my ($self, $value) = @_;
    my $amount_to_store = $self->beetle_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->beetle_stored;
    $self->beetle_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_shake {
    my ($self, $value) = @_;
    my $amount_to_store = $self->shake_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->shake_stored;
    $self->shake_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_burger {
    my ($self, $value) = @_;
    my $amount_to_store = $self->burger_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->burger_stored;
    $self->burger_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_fungus {
    my ($self, $value) = @_;
    my $amount_to_store = $self->fungus_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->fungus_stored;
    $self->fungus_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_syrup {
    my ($self, $value) = @_;
    my $amount_to_store = $self->syrup_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->syrup_stored;
    $self->syrup_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_algae {
    my ($self, $value) = @_;
    my $amount_to_store = $self->algae_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->algae_stored;
    $self->algae_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_meal {
    my ($self, $value) = @_;
    my $amount_to_store = $self->meal_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->meal_stored;
    $self->meal_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_milk {
    my ($self, $value) = @_;
    my $amount_to_store = $self->milk_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->milk_stored;
    $self->milk_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_pancake {
    my ($self, $value) = @_;
    my $amount_to_store = $self->pancake_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->pancake_stored;
    $self->pancake_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_pie {
    my ($self, $value) = @_;
    my $amount_to_store = $self->pie_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->pie_stored;
    $self->pie_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_chip {
    my ($self, $value) = @_;
    my $amount_to_store = $self->chip_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->chip_stored;
    $self->chip_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_soup {
    my ($self, $value) = @_;
    my $amount_to_store = $self->soup_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->soup_stored;
    $self->soup_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_bread {
    my ($self, $value) = @_;
    my $amount_to_store = $self->bread_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->bread_stored;
    $self->bread_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_wheat {
    my ($self, $value) = @_;
    my $amount_to_store = $self->wheat_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->wheat_stored;
    $self->wheat_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_cider {
    my ($self, $value) = @_;
    my $amount_to_store = $self->cider_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->cider_stored;
    $self->cider_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_corn {
    my ($self, $value) = @_;
    my $amount_to_store = $self->corn_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->corn_stored;
    $self->corn_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_root {
    my ($self, $value) = @_;
    my $amount_to_store = $self->root_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->root_stored;
    $self->root_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_apple {
    my ($self, $value) = @_;
    my $amount_to_store = $self->apple_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->apple_stored;
    $self->apple_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_potato {
    my ($self, $value) = @_;
    my $amount_to_store = $self->potato_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->potato_stored;
    $self->potato_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_lapis {
    my ($self, $value) = @_;
    my $amount_to_store = $self->lapis_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->lapis_stored;
    $self->lapis_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub spend_food {
    my ($self, $value) = @_;
    foreach my $type (shuffle FOOD_TYPES) {
        my $method = $type."_stored";
        my $stored = $self->$method;
        if ($stored > $value) {
            $self->$method($stored - $value);
            last;
        }
        else {
            $value -= $stored;
            $self->$method(0);
        }
    }
}

sub add_energy {
    my ($self, $value) = @_;
    my $store = $self->energy_stored + $value;
    my $storage = $self->energy_capacity;
    $self->energy_stored( ($store < $storage) ? $store : $storage );
}

sub spend_energy {
    my ($self, $value) = @_;
    $self->energy_stored( $self->energy_stored - $value );
}

sub add_water {
    my ($self, $value) = @_;
    my $store = $self->water_stored + $value;
    my $storage = $self->water_capacity;
    $self->water_stored( ($store < $storage) ? $store : $storage );
}

sub spend_water {
    my ($self, $value) = @_;
    $self->water_stored( $self->water_stored - $value );
}

sub add_happiness {
    my ($self, $value) = @_;
    my $new = $self->happiness + $value;
    if ($new < 0 && $self->empire->is_noob) {
        $new = 0;
    }
    $self->happiness( $new );
}

sub spend_happiness {
    my ($self, $value) = @_;
    my $new = $self->happiness - $value;
    if ($new < 0 && $self->empire->is_noob) {
        $new = 0;
    }
    $self->happiness( $new );
}

sub add_waste {
    my ($self, $value) = @_;
    my $store = $self->waste_stored + $value;
    my $storage = $self->waste_capacity;
    if ($store < $storage) {
        $self->waste_stored( $store );
    }
    else {
        $self->waste_stored( $storage );
        $self->spend_happiness( $store - $storage ); # pollution
    }
}

sub spend_waste {
    my ($self, $value) = @_;
    $self->waste_stored( $self->waste_stored - $value );
}


no Moose;
__PACKAGE__->meta->make_immutable;
