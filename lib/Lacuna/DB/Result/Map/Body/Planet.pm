package Lacuna::DB::Result::Map::Body::Planet;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body';
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES BUILDABLE_CLASSES);
use List::Util qw(shuffle);
use Lacuna::Util qw(randint format_date);
use DateTime;
no warnings 'uninitialized';

__PACKAGE__->has_many('ships','Lacuna::DB::Result::Ships','body_id');
__PACKAGE__->has_many('plans','Lacuna::DB::Result::Plans','body_id');
__PACKAGE__->has_many('glyphs','Lacuna::DB::Result::Glyphs','body_id');


sub surface {
    my $self = shift;
    return 'surface-'.$self->image;
}


sub ships_travelling { 
    my ($self, $where, $reverse) = @_;
    my $order = '-asc';
    if ($reverse) {
        $order = '-desc';
    }
    $where->{task} = 'Travelling';
    return $self->ships->search(
        $where,
        {
            order_by    => { $order => 'date_available' },
        }
    );
}

sub get_last_attacked_by {
    my $self = shift;
    my $attacker_body_id = Lacuna->cache->get('last_attacked_by',$self->id);
    return undef unless defined $attacker_body_id;
    my $attacker_body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($attacker_body_id);
    return undef unless defined $attacker_body;
    return undef unless $attacker_body->empire_id;
    return $attacker_body;
}

sub set_last_attacked_by {
    my ($self, $attacker_body_id) = @_;
    Lacuna->cache->set('last_attacked_by',$self->id, $attacker_body_id, 60 * 60 * 24 * 30);
}

sub delete_last_attacked_by {
    my $self = shift;
    Lacuna->cache->delete('last_attacked_by',$self->id);
}

# CLAIM

sub claim {
    my ($self, $empire_id) = @_;
    return Lacuna->cache->set('planet_claim_lock', $self->id, $empire_id, 60 * 60 * 24 * 3); # lock it
}

has is_claimed => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Lacuna->cache->get('planet_claim_lock', $self->id);
    }
);

sub claimed_by {
    my $self = shift;
    my $empire_id = $self->is_claimed;
    return $empire_id ? Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id) : undef;    
}

# GLYPHS

sub add_glyph {
    my ($self, $type) = @_;
    return $self->glyphs->new({
        type    => $type,
        body_id => $self->id,
    })->insert;
}

# PLANS
sub get_plan {
    my ($self, $class, $level) = @_;
    return $self->plans->search({class => $class, level => $level},{rows => 1})->single;
}

sub add_plan {
    my ($self, $class, $level, $extra_build_level) = @_;
    my $plans = $self->plans;

    # add it
    return $plans->new({
        body_id             => $self->id,
        class               => $class,
        level               => $level,
        extra_build_level   => $extra_build_level,
    })->insert;
}

sub sanitize {
    my ($self) = @_;
    my $buildings = $self->buildings->search({class => { 'not like' => 'Lacuna::DB::Result::Building::Permanent%' } })->delete_all;
    my @attributes = qw( happiness_hour happiness waste_hour waste_stored waste_capacity
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
        algae_stored syrup_stored fungus_stored burger_stored shake_stored beetle_stored bean_production_hour bean_stored
        restrict_coverage cheese_production_hour cheese_stored
    );
    foreach my $attribute (@attributes) {
        $self->$attribute(0);
    }
    $self->plans->delete;
    $self->glyphs->delete;
    my $incoming = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({foreign_body_id => $self->id});
    while (my $ship = $incoming->next) {
        $ship->turn_around->update;
    }
    $self->ships->delete_all;
    my $enemy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({on_body_id => $self->id});
    while (my $spy = $enemy->next) {
        $spy->on_body_id($spy->from_body_id);
        $spy->update;
    }
    Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({from_body_id => $self->id})->delete_all;
    Lacuna->db->resultset('Lacuna::DB::Result::Market')->search({body_id => $self->id})->delete_all;
    Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({body_id => $self->id})->delete;
    $self->empire_id(undef);
    if ($self->get_type eq 'habitable planet' && $self->size >= 40 && $self->size <= 50) {
        $self->usable_as_starter_enabled(1);
    }
    $self->update;
    return $self;
}

around get_status => sub {
    my ($orig, $self, $empire) = @_;
    my $out = $orig->($self);
    my %ore;
    foreach my $type (ORE_TYPES) {
        $ore{$type} = $self->$type();
    }
    $out->{ore}             = \%ore;
    $out->{water}           = $self->water;
    if ($self->empire_id) {
        $out->{empire} = {
            name            => $self->empire->name,
            id              => $self->empire_id,
            alignment       => $self->empire->is_isolationist ? 'hostile-isolationist' : 'hostile',
            is_isolationist => $self->empire->is_isolationist,
        };
        if (defined $empire) {
            if ($empire->id eq $self->empire_id) {
                if ($self->needs_recalc) {
                    $self->tick; # in case what we just did is going to change our stats
                }
                unless ($empire->is_isolationist) { # don't need to warn about incoming ships if can't be attacked
                    my $now = time;
                    my $incoming_ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
                        {
                            foreign_body_id => $self->id,
                            direction       => 'out',
                            task            => 'Travelling',
                        }
                    );
                    my @colonies;
                    my @allies;
                    while (my $ship = $incoming_ships->next) {
                        if ($ship->date_available->epoch <= $now) {
                            $ship->foreign_body($self);
                            $ship->body->tick;
                        }
                        else {
                            unless (scalar @colonies) { # we don't look it up unless we have incoming
                                @colonies = $empire->planets->get_column('id')->all;
                            }
                            unless (scalar @allies) { # we don't look it up unless we have incoming
                                my $alliance = $empire->alliance if $empire->alliance_id;
                                if (defined $alliance) {
                                    @allies = $alliance->members->get_column('id')->all;
                                }
                            }
                            push @{$out->{incoming_foreign_ships}}, {
                                date_arrives => $ship->date_available_formatted,
                                is_own       => ($ship->body_id ~~ \@colonies) ? 1 : 0,
                                is_ally      => ($ship->body->empire_id ~~ \@allies) ? 1 : 0,
                                id           => $ship->id,
                            };
                        }
                    }
                }
                $out->{needs_surface_refresh} = $self->needs_surface_refresh;
                $out->{empire}{alignment} = 'self';
                $out->{plots_available} = $self->plots_available;
                $out->{building_count}  = $self->building_count;
                $out->{population}      = $self->population;
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
            elsif ($empire->alliance_id && $self->empire->alliance_id == $empire->alliance_id) {
                $out->{empire}{alignment} = $self->empire->is_isolationist ? 'ally-isolationist' : 'ally';
            }
        }
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


# BUILDINGS

has population => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->buildings->search(
            {
               class => { 'not like' => 'Lacuna::DB::Result::Building::Permanent%' }, 
            }
        )->get_column('level')->sum * 10_000;
    },
);

has building_count => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->buildings->search(
            {
               class => { 'not like' => 'Lacuna::DB::Result::Building::Permanent%' }, # these don't count against you 
            }
        )->count;
    },
);

sub get_buildings_of_class {
    my ($self, $class) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Building')->search(
        {
            body_id => $self->id,
            class   => $class,
        },
        {
            order_by    => { -desc => 'level' },
        }
    );
}

sub get_building_of_class {
    my ($self, $class) = @_;
    my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search(
        {
            body_id => $self->id,
            class   => $class,
        },
        {
            order_by    => { -desc => 'level' },
            rows        => 1,
        }
    )->single;
    if (defined $building ) {
        $building->body($self);
    }
    return $building;
}

has command => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $building = $self->get_building_of_class('Lacuna::DB::Result::Building::PlanetaryCommand');
        return undef unless defined $building;
        $building->body($self);
        return $building;
    },
);

has oversight => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $building = $self->get_building_of_class('Lacuna::DB::Result::Building::Oversight');
        return undef unless defined $building;
        $building->body($self);
        return $building;
    },
);

has mining_ministry => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $building = $self->get_building_of_class('Lacuna::DB::Result::Building::Ore::Ministry');
        return undef unless defined $building;
        $building->body($self);
        return $building;
    },
);

has network19 => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $building = $self->get_building_of_class('Lacuna::DB::Result::Building::Network19');
        return undef unless defined $building;
        $building->body($self);
        return $building;
    },
);

has development => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $building = $self->get_building_of_class('Lacuna::DB::Result::Building::Development');
        return undef unless defined $building;
        $building->body($self);
        return $building;
    },
);

has refinery => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $building = $self->get_building_of_class('Lacuna::DB::Result::Building::Ore::Refinery');
        return undef unless defined $building;
        $building->body($self);
        return $building;
    },
);

has spaceport => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $building = $self->get_building_of_class('Lacuna::DB::Result::Building::SpacePort');
        return undef unless defined $building;
        $building->body($self);
        return $building;
    },
);    

has embassy => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $building = $self->get_building_of_class('Lacuna::DB::Result::Building::Embassy');
        return undef unless defined $building;
        $building->body($self);
        return $building;
    },
);    

sub is_space_free {
    my ($self, $x, $y) = @_;
    my $count = $self->buildings->search({x=>$x, y=>$y})->count;
    return 0 if $count > 0;
    return 1;
}

sub find_free_space {
    my $self = shift;
    my $x = randint(-3,5);
    my $y = randint(-5,5);
    if ($self->is_space_free($x, $y)) {
        return ($x, $y);
    }
    else {
        foreach my $x (-5..5) {
            foreach my $y (-5..5) {
                next if $y == 0 && $x == 0;
                if ($self->is_space_free($x, $y)) {
                    return ($x, $y);
                }
            }
        }
    }
    confess [1009, 'No free space found.'];
}

sub check_for_available_build_space {
    my ($self, $x, $y) = @_;
    if ($x > 5 || $x < -5 || $y > 5 || $y < -5) {
        confess [1009, "That's not a valid space for a building.", [$x, $y]];
    }
    unless ($self->is_space_free($x, $y)) {
        confess [1009, "That space is already occupied.", [$x,$y]]; 
    }
    return 1;
}

sub check_plots_available {
    my ($self, $building) = @_;
    if (!$building->isa('Lacuna::DB::Result::Building::Permanent') && $self->plots_available < 1) {
        confess [1009, "You've already reached the maximum number of buildings for this planet.", $self->size];
    }
    return 1;
}

sub has_met_building_prereqs {
    my ($self, $building, $cost) = @_;
    $building->can_build($self);
    $self->has_resources_to_build($building, $cost);
    $self->has_max_instances_of_building($building);
    $self->has_resources_to_operate($building);
    return 1;
}

sub can_build_building {
    my ($self, $building) = @_;
    $self->check_for_available_build_space($building->x, $building->y);
    $self->check_plots_available($building);
    $self->has_room_in_build_queue;
    $self->has_met_building_prereqs($building);
    return $self;
}

sub has_room_in_build_queue {
    my ($self) = shift;
    my $max = 1;
    my $dev_ministry = $self->development;
    if (defined $dev_ministry) {
        $max += $dev_ministry->level;
    }
    my $count = $self->builds->count;
    if ($count >= $max) {
        confess [1009, "There's no room left in the build queue.", $max];
    }
    return 1; 
}

use constant operating_resource_names => qw(food_hour energy_hour ore_hour water_hour);

has future_operating_resources => (
    is      => 'rw',
    clearer => 'clear_future_operating_resources',
    lazy    => 1,
    default => sub {
        my $self = shift;
        
        # get current
        my %future;
        foreach my $method ($self->operating_resource_names) {
            $future{$method} = $self->$method;
        }
        
        # adjust for what's already in build queue
        my $queued_builds = $self->builds;
        while (my $build = $queued_builds->next) {
            $build->body($self);
            my $other = $build->stats_after_upgrade;
            foreach my $method ($self->operating_resource_names) {
                $future{$method} += $other->{$method} - $build->$method;
            }
        }
        return \%future;
    },
);

sub has_resources_to_operate {
    my ($self, $building) = @_;
    
    # get future
    my $future = $self->future_operating_resources;
    
    # get change for this building
    my $after = $building->stats_after_upgrade;

    # check our ability to sustain ourselves
    foreach my $method ($self->operating_resource_names) {
        my $delta = $after->{$method} - $building->$method;
        # don't allow it if it sucks resources && its sucking more than we're producing
        if ($delta < 0 && $future->{$method} + $delta < 0) {
            my $resource = $method;
            $resource =~ s/(\w+)_hour/$1/;
            confess [1012, "Unsustainable. Not enough resources being produced to build this.", $resource];
        }
    }
    return 1;
}

sub has_resources_to_operate_after_building_demolished {
    my ($self, $building) = @_;
    
    # get future
    my $planet = $self->future_operating_resources;

    # check our ability to sustain ourselves
    foreach my $method ($self->operating_resource_names) {
        # don't allow it if it sucks resources && its sucking more than we're producing
        if ($planet->{$method} - $building->$method < 0) {
            my $resource = $method;
            $resource =~ s/(\w+)_hour/$1/;
            confess [1012, "Unsustainable. Not enough resources being produced by other sources to destroy this.", $resource];
        }
    }
    return 1;
}

sub has_resources_to_build {
    my ($self, $building, $cost) = @_;
    $cost ||= $building->cost_to_upgrade;
    foreach my $resource (qw(food energy ore water)) {
        unless ($self->type_stored($resource) >= $cost->{$resource}) {
            confess [1011, "Not enough $resource in storage to build this.", $resource];
        }
    }
    if ($cost->{waste} < 0) { # we're spending waste to build a building, which is unusal, but not wrong
        if ($self->waste_stored < abs($cost->{waste})) {
            confess [1011, "Not enough waste in storage to build this.", 'waste'];
        }
    }
    return 1;
}

sub has_max_instances_of_building {
    my ($self, $building) = @_;
    return 0 if $building->max_instances_per_planet == 9999999;
    my $count = $self->get_buildings_of_class($building->class)->count;
    if ($count >= $building->max_instances_per_planet) {
        confess [1009, sprintf("You are only allowed %s of these buildings per planet.",$building->max_instances_per_planet), [$building->max_instances_per_planet, $count]];
    }
}

sub builds { 
    my ($self, $reverse) = @_;
    my $order = '-asc';
    if ($reverse) {
        $order = '-desc';
    }
    return Lacuna->db->resultset('Lacuna::DB::Result::Building')->search(
        { body_id => $self->id, is_upgrading => 1 },       
        { order_by => { $order => 'upgrade_ends' } }
    );
}

sub get_existing_build_queue_time {
    my $self = shift;
    my $building = $self->builds(1)->search(undef, {rows=>1})->single;
    return (defined $building) ? $building->upgrade_ends : DateTime->now;
}

sub lock_plot {
    my ($self, $x, $y) = @_;
    return Lacuna->cache->set('plot_contention_lock', $self->id.'|'.$x.'|'.$y, 1, 15); # lock it
}

sub is_plot_locked {
    my ($self, $x, $y) = @_;
    return Lacuna->cache->get('plot_contention_lock', $self->id.'|'.$x.'|'.$y);
}

sub build_building {
    my ($self, $building, $in_parallel) = @_;
    unless ($building->isa('Lacuna::DB::Result::Building::Permanent')) {
        $self->building_count( $self->building_count + 1 );
        $self->plots_available( $self->plots_available - 1 );
        $self->update;
    }
    $building->date_created(DateTime->now);
    $building->body_id($self->id);
    $building->level(0) unless $building->level;
    $building->insert;
    $building->body($self);
    $building->start_upgrade(undef, $in_parallel);
}

sub found_colony {
    my ($self, $empire) = @_;
    $self->empire_id($empire->id);
    $self->empire($empire);
    $self->usable_as_starter_enabled(0);
    $self->last_tick(DateTime->now);
    $self->update;    

    # award medal
    my $type = ref $self;
    $type =~ s/^.*::(\w\d+)$/$1/;
    $empire->add_medal($type);

    # add command building
    my $command = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        x               => 0,
        y               => 0,
        class           => 'Lacuna::DB::Result::Building::PlanetaryCommand',
        level           => $empire->growth_affinity - 1,
    });
    $self->build_building($command);
    $command->finish_upgrade;
    
    # add starting resources
    $self->tick;
    $self->add_algae(700);
    $self->add_energy(700);
    $self->add_water(700);
    $self->add_ore(700);
    $self->update;
    
    # newsworthy
    $self->add_news(75,'%s founded a new colony on %s.', $empire->name, $self->name);
        
    return $self;
}

has total_ore_concentration => (
    is          => 'ro',  
    lazy        => 1,
    default     => sub {
        my $self = shift;
        my $tally = 0;
        foreach my $type (ORE_TYPES) {
            $tally += $self->$type;
        }
        return $tally;
    },
);

sub recalc_stats {
    my ($self) = @_;
    my %stats = ( needs_recalc => 0 );
    my $buildings = $self->buildings;
    #reset foods
    foreach my $type (FOOD_TYPES) {
        $stats{$type.'_production_hour'} = 0;
    }
    #calculate building production
    my ($gas_giant_platforms, $terraforming_platforms, $pantheon_of_hagness, $total_ore_production_hour, $ore_production_hour, $ore_consumption_hour) = 0;
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
        $ore_consumption_hour += $building->ore_consumption_hour;
        $ore_production_hour += $building->ore_production_hour;
        $stats{food_consumption_hour} += $building->food_consumption_hour;
        foreach my $type (@{$building->produces_food_items}) {
            my $method = $type.'_production_hour';
            $stats{$method} += $building->$method();
        }
        if ($building->isa('Lacuna::DB::Result::Building::Ore::Ministry')) {
            my $platforms = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->search({planet_id => $self->id});
            while (my $platform = $platforms->next) {
                foreach my $type (ORE_TYPES) {
                    my $method = $type.'_hour';
                    $stats{$method} += $platform->$method();
                    $total_ore_production_hour += $platform->$method();
                }
            }
        }
        if ($building->isa('Lacuna::DB::Result::Building::Permanent::GasGiantPlatform')) {
            $gas_giant_platforms += $building->level;
        }
        if ($building->isa('Lacuna::DB::Result::Building::Permanent::TerraformingPlatform')) {
            $terraforming_platforms += $building->level;
        }
        if ($building->isa('Lacuna::DB::Result::Building::Permanent::PantheonOfHagness')) {
            $pantheon_of_hagness += $building->level;
        }
    }

    # local ore production
    foreach my $type (ORE_TYPES) {
        my $method = $type.'_hour';
        my $domestic_ore_hour = sprintf('%.0f',$self->$type * $ore_production_hour / $self->total_ore_concentration);
        $stats{$method} += $domestic_ore_hour;
        $total_ore_production_hour += $domestic_ore_hour;
    }

    # subtract ore consumption
	foreach my $type (ORE_TYPES) {
		my $method = $type.'_hour';
		$stats{$method} -= sprintf('%.0f', ($total_ore_production_hour) ? $ore_consumption_hour * $stats{$method} / $total_ore_production_hour: 0);
	}

    # overall ore production
    $stats{ore_hour} = $total_ore_production_hour - $ore_consumption_hour;
    
    
    # deal with storage overages
    if ($self->ore_stored > $self->ore_capacity) {
        $self->spend_ore($self->ore_stored - $self->ore_capacity);
    }
    if ($self->food_stored > $self->food_capacity) {
        $self->spend_food($self->food_stored - $self->food_capacity);
    }
    if ($self->water_stored > $self->water_capacity) {
        $self->spend_water($self->water_stored - $self->water_capacity);
    }
    if ($self->energy_stored > $self->energy_capacity) {
        $self->spend_energy($self->energy_stored - $self->energy_capacity);
    }

    # deal with plot usage
    my $max_plots = $self->size + $pantheon_of_hagness;
    if ($self->isa('Lacuna::DB::Result::Map::Body::Planet::GasGiant')) {
        $max_plots = $gas_giant_platforms < $max_plots ? $gas_giant_platforms : $max_plots;
    }
    if ($self->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        if ($self->orbit > $self->empire->max_orbit || $self->orbit < $self->empire->min_orbit) {
            $max_plots = $terraforming_platforms < $max_plots ? $terraforming_platforms : $max_plots;
        }
    }
    $stats{plots_available} = $max_plots - $self->building_count;

    $self->update(\%stats);
    return $self;
}

# NEWS

sub add_news {
    my $self = shift;
    my $chance = shift;
    my $headline = shift;
    if ($self->restrict_coverage) {
        my $network19 = $self->network19;
        if (defined $network19) {
            $chance += $network19->level * 2;
            $chance = $chance / $self->command->level; 
        }
    }
    if (randint(1,100) <= $chance) {
        $headline = sprintf $headline, @_;
        Lacuna->db->resultset('Lacuna::DB::Result::News')->new({
            date_posted => DateTime->now,
            zone        => $self->zone,
            headline    => $headline,
        })->insert;     
        return 1;
    }
    return 0;
}


# RESOURCE MANGEMENT

sub tick {
    my ($self) = @_;
    
    # stop a double tick
    my $cache = Lacuna->cache;
    if ($cache->get('ticking',$self->id)) {
        return undef;
    }
    else {
        $cache->set('ticking',$self->id, 1, 60);
    }
    
    my $now = DateTime->now;
    my $now_epoch = $now->epoch;
    my %todo;
    my $i; # in case 2 things finish at exactly the same time

    # get building tasks
    my $buildings = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search({
        body_id     => $self->id,
        -or         => [
            -and    => [
                is_upgrading    => 1,
                upgrade_ends    => {'<=' => $now},
            ],
            -and    => [
                is_working      => 1,
                work_ends       => {'<=' => $now},
            ],
        ],
    });
    while (my $building = $buildings->next) {
        if ($building->is_upgrading && $building->upgrade_ends->epoch <= $now_epoch) {
            $todo{format_date($building->upgrade_ends).$i} = {
                object  => $building,
                type    => 'building upgraded',
            };
        }
        if ($building->is_working && $building->work_ends->epoch <= $now_epoch) {
            $todo{format_date($building->work_ends).$i} = {
                object  => $building,
                type    => 'building work complete',
            };
        }
        $i++;
    }

    # get ship tasks
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
        body_id         => $self->id,
        date_available  => { '<=' => $now },
        task            => { '!=' => 'Docked' },
    });
    while (my $ship = $ships->next ) {
        if ($ship->task eq 'Travelling') {
            $todo{format_date($ship->date_available).$i} = {
                object  => $ship,
                type    => 'ship arrives',
            };
        }
        elsif ($ship->task eq 'Building') {
            $todo{format_date($ship->date_available).$i} = {
                object  => $ship,
                type    => 'ship built',
            };
        }
        $i++;
    }
    
    # synchronize completion of tasks
    foreach my $key (sort keys %todo) {
        my ($object, $job) = ($todo{$key}{object}, $todo{$key}{type});
        $object->body($self);
        if ($job eq 'ship built') {
            $self->tick_to($object->date_available);
            $object->finish_construction;
        }
        elsif ($job eq 'ship arrives') {
            $self->tick_to($object->date_available);
            $object->arrive;            
        }
        elsif ($job eq 'building work complete') {
            $self->tick_to($object->work_ends);
            $object->finish_work->update;
        }
        elsif ($job eq 'building upgraded') {
            $self->tick_to($object->upgrade_ends);
            $object->finish_upgrade;
        }
    }
    
    # check / clear boosts
    if ($self->boost_enabled) {
        my $empire = $self->empire;
        my $still_enabled = 0;
        foreach my $resource (qw(energy water ore happiness food storage)) {
            my $boost = $resource.'_boost';
            if ($now_epoch > $empire->$boost->epoch) {
                $self->needs_recalc(1);
            }
            else {
                $still_enabled = 1;
            }
        }
        unless ($still_enabled) {
            if (!$self->empire->check_for_repeat_message('boosts_expired')) {  # because each planet could send the message
                $self->empire->send_predefined_message(
                    tags        => ['Alert'],
                    filename    => 'boosts_expired.txt',
                    repeat_check=> 'boosts_expired',
                );
            }
            $self->boost_enabled(0);
        }
    }

    $self->tick_to($now);

    # advance tutorial
    if ($self->empire->tutorial_stage ne 'turing') {
        Lacuna::Tutorial->new(empire=>$self->empire)->finish;
    }
    # clear caches
    $self->clear_future_operating_resources;    
    $cache->delete('ticking', $self->id);
}

sub tick_to {
    my ($self, $now) = @_;
    my $seconds = $now->epoch - $self->last_tick->epoch;
    my $tick_rate = $seconds / 3600;
    $self->last_tick($now);
    if ($self->needs_recalc) {
        $self->recalc_stats;    
    }
    # happiness
    $self->add_happiness(sprintf('%.0f', $self->happiness_hour * $tick_rate));
    
    # waste
    if ($self->waste_hour < 0 ) { # if it gets negative, spend out of storage
        $self->spend_waste(sprintf('%.0f',abs($self->waste_hour) * $tick_rate));
    }
    else {
        $self->add_waste(sprintf('%.0f', $self->waste_hour * $tick_rate));
    }
    
    # energy
    if ($self->energy_hour < 0 ) { # if it gets negative, spend out of storage
        $self->spend_energy(sprintf('%.0f',abs($self->energy_hour) * $tick_rate));
    }
    else {
        $self->add_energy(sprintf('%.0f', $self->energy_hour * $tick_rate));
    }
    
    # water
    if ($self->water_hour < 0 ) { # if it gets negative, spend out of storage
        $self->spend_water(sprintf('%.0f',abs($self->water_hour) * $tick_rate));
    }
    else {
        $self->add_water(sprintf('%.0f', $self->water_hour * $tick_rate));
    }
    
    # ore
    foreach my $type (ORE_TYPES) {
        my $hour_method = $type.'_hour';
        if ($self->$hour_method < 0 ) { # if it gets negative, spend out of storage
            $self->spend_ore_type($type, sprintf('%.0f',abs($self->$hour_method) * $tick_rate));
        }
        else {
            $self->add_ore_type($type, sprintf('%.0f', $self->$hour_method * $tick_rate));
        }
    }
    
    # food
    my %food;
    my $food_produced;
    foreach my $type (FOOD_TYPES) {
        my $production_hour_method = $type.'_production_hour';
        $food{$type} = sprintf('%.0f', $self->$production_hour_method() * $tick_rate);
        $food_produced += $food{$type};
    }
    # subtract food consumption and save
    if ($food_produced > 0) {
        my $food_consumed = sprintf('%.0f', $self->food_consumption_hour * $tick_rate);
        foreach my $type (FOOD_TYPES) {
            $food{$type} -= sprintf('%.0f', ($food{$type} * $food_consumed) / $food_produced);
            $self->add_food_type($type, $food{$type});
        }
    }
    else {
        $self->spend_food(abs($food_produced));
    }
    
    $self->update;
}

sub type_stored {
    my ($self, $type, $value) = @_;
    my $stored_method = $type.'_stored';
    if (defined $value) {
        $self->$stored_method($value);
    }
    return $self->$stored_method;
}

sub can_spend_type {
    my ($self, $type, $value) = @_;
    my $stored = $type.'_stored';
    if ($self->$stored < $value) {
        confess [1009, "You don't have enough $type in storage."];
    }
    return 1;
}

sub spend_type {
    my ($self, $type, $value) = @_;
    my $method = 'spend_'.$type;
    $self->$method($value);
    return $self;
}

sub can_add_type {
    my ($self, $type, $value) = @_;
    if ($type ~~ [ORE_TYPES]) {
        $type = 'ore';
    }
    if ($type ~~ [FOOD_TYPES]) {
        $type = 'food';
    }
    my $capacity = $type.'_capacity';
    my $stored = $type.'_stored';
    my $available_storage = $self->$capacity - $self->$stored;
    unless ($available_storage >= $value) {
        confess [1009, "You don't have enough available storage."];
    }
    return 1;
}

sub add_type {
    my ($self, $type, $value) = @_;
    my $method = 'add_'.$type;
    unless (eval{$self->can_add_type($type, $value)}) {
        my $empire = $self->empire;
        if (defined $empire && !$empire->skip_resource_warnings && !$empire->check_for_repeat_message('complaint_overflow'.$self->id)) {
            $empire->send_predefined_message(
                filename    => 'complaint_overflow.txt',
                params      => [$type, $self->id, $self->name],
                repeat_check=> 'complaint_overflow'.$self->id,
                tags        => ['Alert'],
            );
        }
        
    }
    $self->$method($value);
    return $self;
}

sub ore_stored {
    my ($self) = @_;
    my $tally = 0;
    foreach my $ore (ORE_TYPES) {
        $tally += $self->type_stored($ore);
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
    return $self;
}

sub add_ore_type {
    my ($self, $type, $amount_requested) = @_;
    my $available_storage = $self->ore_capacity - $self->ore_stored;
    $available_storage = 0 if ($available_storage < 0);
    my $amount_to_add = ($amount_requested <= $available_storage) ? $amount_requested : $available_storage;
    $self->type_stored($type, $self->type_stored($type) + $amount_to_add );
    return $self;
}

sub spend_ore_type {
    my ($self, $type, $amount_spent) = @_;
    my $amount_stored = $self->type_stored($type);
    if ($amount_spent > $amount_stored && $amount_spent > 0) {
        my $difference = $amount_spent - $amount_stored;
        $self->spend_happiness($difference);
        $self->type_stored($type, 0);
        $self->complain_about_lack_of_resources('ore') if ((($difference * 100) / $amount_spent) > 5); # help avoid rounding errors causing messages
    }
    else {
        $self->type_stored($type, $amount_stored - $amount_spent );
    }
    return $self;
}

sub add_magnetite {
    my ($self, $value) = @_;
    return $self->add_ore_type('magnetite', $value);
}

sub spend_magnetite {
    my ($self, $value) = @_;
    return $self->spend_ore_type('magnetite', $value);
}

sub add_beryl {
    my ($self, $value) = @_;
    return $self->add_ore_type('beryl', $value);
}

sub spend_beryl {
    my ($self, $value) = @_;
    return $self->spend_ore_type('beryl', $value);
}

sub add_fluorite {
    my ($self, $value) = @_;
    return $self->add_ore_type('fluorite', $value);
}

sub spend_fluorite {
    my ($self, $value) = @_;
    return $self->spend_ore_type('fluorite', $value);
}

sub add_monazite {
    my ($self, $value) = @_;
    return $self->add_ore_type('monazite', $value);
}

sub spend_monazite {
    my ($self, $value) = @_;
    return $self->spend_ore_type('monazite', $value);
}

sub add_zircon {
    my ($self, $value) = @_;
    return $self->add_ore_type('zircon', $value);
}

sub spend_zircon {
    my ($self, $value) = @_;
    return $self->spend_ore_type('zircon', $value);
}

sub add_sulfur {
    my ($self, $value) = @_;
    return $self->add_ore_type('sulfur', $value);
}

sub spend_sulfur {
    my ($self, $value) = @_;
    return $self->spend_ore_type('sulfur', $value);
}

sub add_anthracite {
    my ($self, $value) = @_;
    return $self->add_ore_type('anthracite', $value);
}

sub spend_anthracite {
    my ($self, $value) = @_;
    return $self->spend_ore_type('anthracite', $value);
}

sub add_methane {
    my ($self, $value) = @_;
    return $self->add_ore_type('methane', $value);
}

sub spend_methane {
    my ($self, $value) = @_;
    return $self->spend_ore_type('methane', $value);
}

sub add_kerogen {
    my ($self, $value) = @_;
    return $self->add_ore_type('kerogen', $value);
}

sub spend_kerogen {
    my ($self, $value) = @_;
    return $self->spend_ore_type('kerogen', $value);
}

sub add_trona {
    my ($self, $value) = @_;
    return $self->add_ore_type('trona', $value);
}

sub spend_trona {
    my ($self, $value) = @_;
    return $self->spend_ore_type('trona', $value);
}

sub add_gypsum {
    my ($self, $value) = @_;
    return $self->add_ore_type('gypsum', $value);
}

sub spend_gypsum {
    my ($self, $value) = @_;
    return $self->spend_ore_type('gypsum', $value);
}

sub add_halite {
    my ($self, $value) = @_;
    return $self->add_ore_type('halite', $value);
}

sub spend_halite {
    my ($self, $value) = @_;
    return $self->spend_ore_type('halite', $value);
}

sub add_goethite {
    my ($self, $value) = @_;
    return $self->add_ore_type('goethite', $value);
}

sub spend_goethite {
    my ($self, $value) = @_;
    return $self->spend_ore_type('goethite', $value);
}

sub add_bauxite {
    my ($self, $value) = @_;
    return $self->add_ore_type('bauxite', $value);
}

sub spend_bauxite {
    my ($self, $value) = @_;
    return $self->spend_ore_type('bauxite', $value);
}

sub add_uraninite {
    my ($self, $value) = @_;
    return $self->add_ore_type('uraninite', $value);
}

sub spend_uraninite {
    my ($self, $value) = @_;
    return $self->spend_ore_type('uraninite', $value);
}

sub add_gold {
    my ($self, $value) = @_;
    return $self->add_ore_type('gold', $value);
}

sub spend_gold {
    my ($self, $value) = @_;
    return $self->spend_ore_type('gold', $value);
}

sub add_galena {
    my ($self, $value) = @_;
    return $self->add_ore_type('galena', $value);
}

sub spend_galena {
    my ($self, $value) = @_;
    return $self->spend_ore_type('galena', $value);
}

sub add_chalcopyrite {
    my ($self, $value) = @_;
    return $self->add_ore_type('chalcopyrite', $value);
}

sub spend_chalcopyrite {
    my ($self, $value) = @_;
    return $self->spend_ore_type('chalcopyrite', $value);
}

sub add_chromite {
    my ($self, $value) = @_;
    return $self->add_ore_type('chromite', $value);
}

sub spend_chromite {
    my ($self, $value) = @_;
    return $self->spend_ore_type('chromite', $value);
}

sub add_rutile {
    my ($self, $value) = @_;
    return $self->add_ore_type('rutile', $value);
}

sub spend_rutile {
    my ($self, $value) = @_;
    return $self->spend_ore_type('rutile', $value);
}

sub spend_ore {
    my ($self, $ore_consumed) = @_;

    # take inventory
    my $ore_stored;
    foreach my $type (ORE_TYPES) {
        $ore_stored += $self->type_stored($type);
    }
    
    # spend proportionally and save
    if ($ore_stored) {
        foreach my $type (ORE_TYPES) {
            $self->spend_ore_type($type, sprintf('%.0f', ($ore_consumed * $self->type_stored($type)) / $ore_stored));
        }
    }
    return $self;
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
        $tally += $self->type_stored($food);
    }
    return $tally;
}

sub add_food_type {
    my ($self, $type, $amount_requested) = @_;
    my $available_storage = $self->food_capacity - $self->food_stored;
    $available_storage = 0 if ($available_storage < 0);
    my $amount_to_add = ($amount_requested <= $available_storage) ? $amount_requested : $available_storage;
    $self->type_stored($type, $self->type_stored($type) + $amount_to_add );
    return $self;
}

sub spend_food_type {
    my ($self, $type, $amount_spent) = @_;
    my $amount_stored = $self->type_stored($type);
    if ($amount_spent > $amount_stored) {
        $self->spend_happiness($amount_spent - $amount_stored);
        $self->type_stored($type, 0);
        $self->complain_about_lack_of_resources('food');
    }
    else {
        $self->type_stored($type, $amount_stored - $amount_spent );
    }
    return $self;
}

sub add_beetle {
    my ($self, $value) = @_;
    return $self->add_food_type('beetle', $value);
}

sub spend_beetle {
    my ($self, $value) = @_;
    return $self->spend_food_type('beetle', $value);
}

sub add_shake {
    my ($self, $value) = @_;
    return $self->add_food_type('shake', $value);
}

sub spend_shake {
    my ($self, $value) = @_;
    return $self->spend_food_type('shake', $value);
}

sub add_burger {
    my ($self, $value) = @_;
    return $self->add_food_type('burger', $value);
}

sub spend_burger {
    my ($self, $value) = @_;
    return $self->spend_food_type('burger', $value);
}

sub add_fungus {
    my ($self, $value) = @_;
    return $self->add_food_type('fungus', $value);
}

sub spend_fungus {
    my ($self, $value) = @_;
    return $self->spend_food_type('fungus', $value);
}

sub add_syrup {
    my ($self, $value) = @_;
    return $self->add_food_type('syrup', $value);
}

sub spend_syrup {
    my ($self, $value) = @_;
    return $self->spend_food_type('syrup', $value);
}

sub add_algae {
    my ($self, $value) = @_;
    return $self->add_food_type('algae', $value);
}

sub spend_algae {
    my ($self, $value) = @_;
    return $self->spend_food_type('algae', $value);
}

sub add_meal {
    my ($self, $value) = @_;
    return $self->add_food_type('meal', $value);
}

sub spend_meal {
    my ($self, $value) = @_;
    return $self->spend_food_type('meal', $value);
}

sub add_milk {
    my ($self, $value) = @_;
    return $self->add_food_type('milk', $value);
}

sub spend_milk {
    my ($self, $value) = @_;
    return $self->spend_food_type('milk', $value);
}

sub add_pancake {
    my ($self, $value) = @_;
    return $self->add_food_type('pancake', $value);
}

sub spend_pancake {
    my ($self, $value) = @_;
    return $self->spend_food_type('pancake', $value);
}

sub add_pie {
    my ($self, $value) = @_;
    return $self->add_food_type('pie', $value);
}

sub spend_pie {
    my ($self, $value) = @_;
    return $self->spend_food_type('pie', $value);
}

sub add_chip {
    my ($self, $value) = @_;
    return $self->add_food_type('chip', $value);
}

sub spend_chip {
    my ($self, $value) = @_;
    return $self->spend_food_type('chip', $value);
}

sub add_soup {
    my ($self, $value) = @_;
    return $self->add_food_type('soup', $value);
}

sub spend_soup {
    my ($self, $value) = @_;
    return $self->spend_food_type('soup', $value);
}

sub add_bread {
    my ($self, $value) = @_;
    return $self->add_food_type('bread', $value);
}

sub spend_bread {
    my ($self, $value) = @_;
    return $self->spend_food_type('bread', $value);
}

sub add_wheat {
    my ($self, $value) = @_;
    return $self->add_food_type('wheat', $value);
}

sub spend_wheat {
    my ($self, $value) = @_;
    return $self->spend_food_type('wheat', $value);
}

sub add_cider {
    my ($self, $value) = @_;
    return $self->add_food_type('cider', $value);
}

sub spend_cider {
    my ($self, $value) = @_;
    return $self->spend_food_type('cider', $value);
}

sub add_corn {
    my ($self, $value) = @_;
    return $self->add_food_type('corn', $value);
}

sub spend_corn {
    my ($self, $value) = @_;
    return $self->spend_food_type('corn', $value);
}

sub add_root {
    my ($self, $value) = @_;
    return $self->add_food_type('root', $value);
}

sub spend_root {
    my ($self, $value) = @_;
    return $self->spend_food_type('root', $value);
}

sub add_bean {
    my ($self, $value) = @_;
    return $self->add_food_type('bean', $value);
}

sub spend_bean {
    my ($self, $value) = @_;
    return $self->spend_food_type('bean', $value);
}

sub add_cheese {
    my ($self, $value) = @_;
    return $self->add_food_type('cheese', $value);
}

sub spend_cheese {
    my ($self, $value) = @_;
    return $self->spend_food_type('cheese', $value);
}

sub add_apple {
    my ($self, $value) = @_;
    return $self->add_food_type('apple', $value);
}

sub spend_apple {
    my ($self, $value) = @_;
    return $self->spend_food_type('apple', $value);
}

sub add_potato {
    my ($self, $value) = @_;
    return $self->add_food_type('potato', $value);
}

sub spend_potato {
    my ($self, $value) = @_;
    return $self->spend_food_type('potato', $value);
}

sub add_lapis {
    my ($self, $value) = @_;
    return $self->add_food_type('lapis', $value);
}

sub spend_lapis {
    my ($self, $value) = @_;
    return $self->spend_food_type('lapis', $value);
}

sub spend_food {
    my ($self, $food_consumed) = @_;
    
    # take inventory
    my $food_stored;
    my $food_type_count = 0;
    foreach my $type (FOOD_TYPES) {
        my $stored = $self->type_stored($type);
        $food_stored += $stored;
        $food_type_count++ if ($stored);
    }
    
    # spend proportionally and save
    if ($food_stored) {
        foreach my $type (FOOD_TYPES) {
            $self->spend_food_type($type, sprintf('%.0f', ($food_consumed * $self->type_stored($type)) / $food_stored));
        }
    }
    
    # adjust happiness based on food diversity
    if ($food_type_count > 3) {
        $self->add_happiness($food_consumed);
    }
    elsif ($food_type_count < 3) {
        $self->spend_happiness($food_consumed);
        my $empire = $self->empire;
        if (!$empire->skip_resource_warnings && $empire->university_level > 2 && !$empire->check_for_repeat_message('complaint_food_diversity')) {
            $empire->send_predefined_message(
                filename    => 'complaint_food_diversity.txt',
                params      => [$self->id, $self->name],
                repeat_check=> 'complaint_food_diversity',
                tags        => ['Alert'],
            );
        }
    }
    return $self;
}

sub add_energy {
    my ($self, $value) = @_;
    my $store = $self->energy_stored + $value;
    my $storage = $self->energy_capacity;
    $self->energy_stored( ($store < $storage) ? $store : $storage );
    return $self;
}

sub spend_energy {
    my ($self, $amount_spent) = @_;
    my $amount_stored = $self->energy_stored;
    if ($amount_spent > $amount_stored) {
        $self->spend_happiness($amount_spent - $amount_stored);
        $self->energy_stored(0);
        $self->complain_about_lack_of_resources('energy');
    }
    else {
        $self->energy_stored( $amount_stored - $amount_spent );
    }
    return $self;
}

sub add_water {
    my ($self, $value) = @_;
    my $store = $self->water_stored + $value;
    my $storage = $self->water_capacity;
    $self->water_stored( ($store < $storage) ? $store : $storage );
    return $self;
}

sub spend_water {
    my ($self, $amount_spent) = @_;
    my $amount_stored = $self->water_stored;
    if ($amount_spent > $amount_stored) {
        $self->spend_happiness($amount_spent - $amount_stored);
        $self->water_stored(0);
        $self->complain_about_lack_of_resources('water');
    }
    else {
        $self->water_stored( $amount_stored - $amount_spent );
    }
    return $self;
}

sub add_happiness {
    my ($self, $value) = @_;
    my $new = $self->happiness + $value;
    if ($new < 0 && $self->empire->is_isolationist) {
        $new = 0;
    }
    $self->happiness( $new );
    return $self;
}

sub spend_happiness {
    my ($self, $value) = @_;
    my $new = $self->happiness - $value;
    my $empire = $self->empire;
    if ($new < 0) {
        if ($empire->is_isolationist) {
            $new = 0;
        }
        elsif (!$empire->skip_happiness_warnings && !$empire->check_for_repeat_message('complaint_unhappy')) {
            $empire->send_predefined_message(
                filename    => 'complaint_unhappy.txt',
                params      => [$self->id, $self->name],
                repeat_check=> 'complaint_unhappy',
                tags        => ['Alert'],
            );
        }
    }
    $self->happiness( $new );
    return $self;
}

sub add_waste {
    my ($self, $value) = @_;
    my $store = $self->waste_stored + $value;
    my $storage = $self->waste_capacity;
    if ($store < $storage) {
        $self->waste_stored( $store );
    }
    else {
        my $empire = $self->empire;
        $self->waste_stored( $storage );
        $self->spend_happiness( $store - $storage ); # pollution
        if (!$empire->skip_pollution_warnings && $empire->university_level > 2 && !$empire->check_for_repeat_message('complaint_pollution')) {
            $empire->send_predefined_message(
                filename    => 'complaint_pollution.txt',
                params      => [$self->id, $self->name],
                repeat_check=> 'complaint_pollution',
                tags        => ['Alert'],
            );
        }
    }
    return $self;
}

sub spend_waste {
    my ($self, $value) = @_;
    if ($self->waste_stored >= $value) {
        $self->waste_stored( $self->waste_stored - $value );
    }
    else { # if they run out of waste in storage, then the citizens start bitching
        $self->spend_happiness($value);
        my $empire = $self->empire;
        if (!$empire->check_for_repeat_message('complaint_lack_of_waste')) {
            my $building_name;
            foreach my $class (qw(Lacuna::DB::Result::Building::Energy::Waste Lacuna::DB::Result::Building::Waste::Treatment Lacuna::DB::Result::Building::Waste::Digester Lacuna::DB::Result::Building::Water::Reclamation)) {
                my $building = $self->get_buildings_of_class($class)->search({efficiency => {'>' => 0}},{rows => 1})->single;
                if (defined $building) {
                    $building_name = $building->name;
                    $building->spend_efficiency(25)->update;
                    last;
                }
            }
            if ($building_name && !$empire->skip_resource_warnings) {
                $empire->send_predefined_message(
                    filename    => 'complaint_lack_of_waste.txt',
                    params      => [$building_name, $self->id, $self->name, $building_name],
                    repeat_check=> 'complaint_lack_of_waste',
                    tags        => ['Alert'],
                );
            }
        }
    }
    return $self;
}

sub complain_about_lack_of_resources {
    my ($self, $resource) = @_;
    my $empire = $self->empire;
    # if they run out of resources in storage, then the citizens start bitching
    if (!$empire->check_for_repeat_message('complaint_lack_of_'.$resource)) {
        my $building_name;
        foreach my $rpcclass (shuffle BUILDABLE_CLASSES) {
            my $class = $rpcclass->model_class;
            next unless ('Infrastructure' ~~ [$class->build_tags]);
            my $building = $self->get_buildings_of_class($class)->search({efficiency => {'>' => 0}},{rows => 1})->single;
            if (defined $building) {
                $building_name = $building->name;
                $building->spend_efficiency(25)->update;
                last;
            }
        }
        if ($building_name && !$empire->skip_resource_warnings) {
            $empire->send_predefined_message(
                filename    => 'complaint_lack_of_'.$resource.'.txt',
                params      => [$self->id, $self->name, $building_name],
                repeat_check=> 'complaint_lack_of_'.$resource,
                tags        => ['Alert'],
            );
        }
    }
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
