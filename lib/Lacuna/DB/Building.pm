package Lacuna::DB::Building;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Constants ':all';

__PACKAGE__->set_domain_name('building');
__PACKAGE__->add_attributes(
    date_created    => { isa => 'DateTime' },
    body_id         => { isa => 'Str' },
    empire_id       => { isa => 'Str' },
    x               => { isa => 'Int' },
    y               => { isa => 'Int' },
    level           => { isa => 'Int' },
    class           => { isa => 'Str' },
    build_queue_id  => { isa => 'Str' },
);

__PACKAGE__->belongs_to('build_queue', 'Lacuna::DB::BuildQueue', 'build_queue_id', mate=>'building');
__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');
__PACKAGE__->belongs_to('body', 'Lacuna::DB::Body', 'body_id');
__PACKAGE__->recast_using('class');

sub controller_class {
    confess "you need to override me";
}

use constant max_instances_per_planet => 9999999;

use constant university_prereq => 0;

use constant min_orbit => 1;

use constant max_orbit => 7;

use constant building_prereq => {};

use constant name => 'Building';

sub image {
    confess 'override me';
}

sub image_level {
    my ($self) = @_;
    my $level = ($self->level > 9) ? 9 : $self->level;
    return $self->image.$level;
}

use constant time_to_build => 60;

use constant energy_to_build => 0;

use constant food_to_build => 0;

use constant ore_to_build => 0;

use constant water_to_build => 0;

use constant waste_to_build => 0;

use constant happiness_consumption => 0;

use constant energy_consumption => 0;

use constant water_consumption => 0;

use constant waste_consumption => 0;

use constant food_consumption => 0;

use constant ore_consumption => 0;

use constant happiness_production => 0;

use constant energy_production => 0;

use constant water_production => 0;

use constant waste_production => 0;

use constant beetle_production => 0;

use constant shake_production => 0;

use constant burger_production => 0;

use constant fungus_production => 0;

use constant syrup_production => 0;

use constant algae_production => 0;

use constant meal_production => 0;

use constant milk_production => 0;

use constant pancake_production => 0;

use constant pie_production => 0;

use constant chip_production => 0;

use constant soup_production => 0;

use constant bread_production => 0;

use constant wheat_production => 0;

use constant cider_production => 0;

use constant corn_production => 0;

use constant root_production => 0;

use constant bean_production => 0;

use constant cheese_production => 0;

use constant apple_production => 0;

use constant lapis_production => 0;

use constant potato_production => 0;

use constant ore_production => 0;

use constant water_storage => 0;

use constant energy_storage => 0;

use constant food_storage => 0;

use constant ore_storage => 0;

use constant waste_storage => 0;

# BASE FORMULAS

sub production_hour {
    my $level = $_[0]->level;
    return 0 unless $level;
    return (GROWTH ** ( $level - 1));
}

sub upgrade_cost {
    return (INFLATION ** $_[0]->level);
}

sub consumption_hour {
    $_[0]->production_hour;
}

# PRODUCTION

sub farming_production_bonus {
    my ($self) = @_;
    return (100 + $self->empire->species->farming_affinity) / 100;
}

sub lapis_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->lapis_production * $self->production_hour * $self->farming_production_bonus);
}

sub potato_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->potato_production * $self->production_hour * $self->farming_production_bonus);
}

sub bean_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->bean_production * $self->production_hour * $self->farming_production_bonus);
}

sub cheese_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->cheese_production * $self->production_hour);
}

sub apple_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->apple_production * $self->production_hour * $self->farming_production_bonus);
}

sub root_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->root_production * $self->production_hour * $self->farming_production_bonus);
}

sub corn_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->corn_production * $self->production_hour * $self->farming_production_bonus);
}

sub cider_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->cider_production * $self->production_hour);
}

sub wheat_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->wheat_production * $self->production_hour * $self->farming_production_bonus);
}

sub bread_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->bread_production * $self->production_hour);
}

sub soup_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->soup_production * $self->production_hour);
}

sub chip_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->chip_production * $self->production_hour);
}

sub pie_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->pie_production * $self->production_hour);
}

sub pancake_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->pancake_production * $self->production_hour);
}

sub milk_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->milk_production * $self->production_hour * $self->farming_production_bonus);
}

sub meal_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->meal_production * $self->production_hour);
}

sub algae_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->algae_production * $self->production_hour * $self->farming_production_bonus);
}

sub syrup_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->syrup_production * $self->production_hour);
}

sub fungus_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->fungus_production * $self->production_hour * $self->farming_production_bonus);
}

sub burger_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->burger_production * $self->production_hour);
}

sub shake_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->shake_production * $self->production_hour);
}

sub beetle_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->beetle_production * $self->production_hour * $self->farming_production_bonus);
}

sub food_production_hour {
    my ($self) = @_;
    my $tally = 0;
    foreach my $food (FOOD_TYPES) {
        my $method = $food."_production_hour";
        $tally += $self->$method;
    }
    return $tally;
}

sub food_consumption_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->food_consumption * $self->consumption_hour);
}

sub food_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->food_production_hour - $self->food_consumption_hour);
}

sub energy_production_bonus {
    my ($self) = @_;
    return (100 + $self->empire->species->science_affinity) / 100;
}

sub energy_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->energy_production * $self->production_hour * $self->energy_production_bonus);
}

sub energy_consumption_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->energy_consumption * $self->consumption_hour);
}

sub energy_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->energy_production_hour - $self->energy_consumption_hour);
}

sub mining_production_bonus {
    my ($self) = @_;
    return (100 + $self->empire->species->mining_affinity) / 100;
}

sub ore_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->ore_production * $self->production_hour * $self->mining_production_bonus);
}

sub ore_consumption_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->ore_consumption * $self->consumption_hour);
}

sub ore_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->ore_production_hour - $self->ore_consumption_hour);
}

sub water_production_bonus {
    my ($self) = @_;
    return (100 + $self->empire->species->environmental_affinity) / 100;
}

sub water_production_hour {
    my ($self) = @_;
    return sprintf('%.0f', $self->water_production * $self->production_hour * $self->water_production_bonus);
}

sub water_consumption_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->water_consumption * $self->consumption_hour);
}

sub water_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->water_production_hour - $self->water_consumption_hour);
}

sub waste_consumption_bonus {
    my ($self) = @_;
    return (100 + $self->empire->species->environmental_affinity) / 100;
}

sub waste_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->waste_production * $self->production_hour);
}

sub waste_consumption_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->waste_consumption * $self->consumption_hour * $self->waste_consumption_bonus);
}

sub waste_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->waste_production_hour - $self->waste_consumption_hour);
}

sub happiness_production_bonus {
    my ($self) = @_;
    return (100 + ($self->empire->species->political_affinity * 2)) / 100;
}

sub happiness_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->happiness_production * $self->production_hour * $self->happiness_production_bonus);
}

sub happiness_consumption_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->happiness_consumption * $self->consumption_hour);
}

sub happiness_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->happiness_production_hour - $self->waste_consumption_hour);
}

# STORAGE

sub food_capacity {
    my ($self) = @_;
    return sprintf('%.0f',$self->food_storage * $self->production_hour);
}

sub energy_capacity {
    my ($self) = @_;
    return sprintf('%.0f',$self->energy_storage * $self->production_hour);
}

sub ore_capacity {
    my ($self) = @_;
    return sprintf('%.0f',$self->ore_storage * $self->production_hour);
}

sub water_capacity {
    my ($self) = @_;
    return sprintf('%.0f',$self->water_storage * $self->production_hour);
}

sub waste_capacity {
    my ($self) = @_;
    return sprintf('%.0f',$self->waste_storage * $self->production_hour);
}

# BUILD

sub check_build_prereqs {
    my ($self, $body) = @_;
    
    # check goldilox zone
    if ($body->orbit < $self->min_orbit || $body->orbit > $self->max_orbit) {
        confess [1013, "Can't build a building outside of it's Goldilox zone."];
    }
    
    # check university level
    if ($self->university_prereq > $body->empire->university_level) {
        confess [1013, "University research too low.",$self->university_prereq];
    }

    # check building prereqs
    my $db = $self->simpledb;
    my $prereqs = $self->building_prereq;
    foreach my $key (keys %{$prereqs}) {
        my $count = $db->domain($key)->count(where=>{body_id=>$body->id, class=>$key, level=>['>=',$prereqs->{$key}]});
        if ($count < 1) {
            confess [1013, "You don't have the necessary prerequisite buildings.",[$key, $prereqs->{$key}]];
        }
    }
    
    return 1;
}



# UPGRADES

sub has_met_upgrade_prereqs {
    my ($self) = @_;
    if (ref $self ne 'Lacuna::DB::Building::University' && $self->level >= $self->empire->university_level) {
        confess [1013, "You cannot upgrade a building past your university level."];
    }
    return 1;
}

sub has_no_pending_build {
    my ($self) = @_;
    my $queue = $self->build_queue if ($self->build_queue_id);
    if (defined $queue && $queue->seconds_remaining > 0) {
        confess [1010, "You must complete the pending build first."];
    }
    return 1;
}

sub can_upgrade {
    my ($self, $cost) = @_;
    my $body = $self->body;
    $body->tick;
    $body->has_resources_to_build($self,$cost);
    $body->has_resources_to_operate($self);
    $self->has_met_upgrade_prereqs();
    $self->has_no_pending_build();
    return 1;
}

sub construction_cost_reduction_bonus {
    my $self = shift;
    return (100 - $self->empire->species->research_affinity) / 100
}

sub manufacturing_cost_reduction_bonus {
    my $self = shift;
    return (100 - $self->empire->species->manufacturing_affinity) / 100
}

sub time_cost_reduction_bonus {
    my ($self, $extra) = @_;
    $extra ||= 0;
    return (100 - $extra - $self->empire->species->management_affinity) / 100
}

sub cost_to_upgrade {
    my ($self) = @_;
    my $upgrade_cost = $self->upgrade_cost;
    my $upgrade_cost_reduction = $self->construction_cost_reduction_bonus;
    return {
        food    => sprintf('%.0f',$self->food_to_build * $upgrade_cost * $upgrade_cost_reduction),
        energy  => sprintf('%.0f',$self->energy_to_build * $upgrade_cost * $upgrade_cost_reduction),
        ore     => sprintf('%.0f',$self->ore_to_build * $upgrade_cost * $upgrade_cost_reduction),
        water   => sprintf('%.0f',$self->water_to_build * $upgrade_cost * $upgrade_cost_reduction),
        waste   => sprintf('%.0f',$self->waste_to_build * $upgrade_cost * $upgrade_cost_reduction),
        time    => sprintf('%.0f',$self->time_to_build * $upgrade_cost * $self->time_cost_reduction_bonus),
    };
}

sub stats_after_upgrade {
    my ($self) = @_;
    my $current_level = $self->level;
    $self->level($current_level + 1);
    my %stats = (
        food_hour       => $self->food_hour,
        energy_hour     => $self->energy_hour,
        ore_hour        => $self->ore_hour,
        water_hour      => $self->water_hour,
        waste_hour      => $self->waste_hour,
        happiness_hour  => $self->happiness_hour,
        );
    $self->level($current_level);
    return \%stats;
}

sub start_upgrade {
    my ($self, $cost) = @_;  
    $cost ||= $self->cost_to_upgrade;
    
    # add to queue
    my $queue = $self->simpledb->domain('build_queue')->insert({
        date_created        => DateTime->now,
        date_complete       => DateTime->now->add(seconds=>$cost->{time}),
        building_id         => $self->id,
        empire_id           => $self->empire->id,
        building_class      => $self->class,
        body_id             => $self->body_id,
    });
    $self->build_queue_id($queue->id);
    $self->put;
}

sub finish_upgrade {
    my ($self) = @_;
    $self->build_queue->delete;
    $self->level($self->level + 1);
    $self->build_queue_id('');
    $self->put;
    $self->body($self->body->recalc_stats);
    $self->empire->add_medal('building'.$self->level);
    my $type = $self->controller_class;
    $type =~ s/^Lacuna::Building::(\w+)$/$1/;
    $self->empire->add_medal($type);
}

no Moose;
__PACKAGE__->meta->make_immutable;
