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

__PACKAGE__->belongs_to('build_queue', 'Lacuna::DB::BuildQueue', 'build_queue_id');
__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');
__PACKAGE__->belongs_to('body', 'Lacuna::DB::Body', 'body_id');
__PACKAGE__->recast_using('class');

has max_instances_per_planet => (
    is      => 'ro',
    default => 9999999,
);

has university_prereq => (
    is      => 'ro',
    default => 0,
);

has building_prereq => (
    is      => 'ro',
    default => sub {{}},
    lazy    => 1,
);

has name => (
    is      => 'ro',
    default => 'Building',
);

has image => (
    is      => 'ro',
    default => undef,
);

has time_to_build => (
    is      => 'ro',
    default => '60',
);

has energy_to_build => (
    is      => 'ro',
    default => 0,
);

has food_to_build => (
    is      => 'ro',
    default => 0,
);

has ore_to_build => (
    is      => 'ro',
    default => 0,
);

has water_to_build => (
    is      => 'ro',
    default => 0,
);

has waste_to_build => (
    is      => 'ro',
    default => 0,
);

has happiness_consumption => (
    is      => 'ro',
    default => 0,
);

has energy_consumption => (
    is      => 'ro',
    default => 0,
);

has water_consumption => (
    is      => 'ro',
    default => 0,
);

has waste_consumption => (
    is      => 'ro',
    default => 0,
);

has food_consumption => (
    is      => 'ro',
    default => 0,
);

has ore_consumption => (
    is      => 'ro',
    default => 0,
);

has happiness_production => (
    is      => 'ro',
    default => 0,
);

has energy_production => (
    is      => 'ro',
    default => 0,
);

has water_production => (
    is      => 'ro',
    default => 0,
);

has waste_production => (
    is      => 'ro',
    default => 0,
);

has beetle_production => (
    is      => 'ro',
    default => 0,
);

has shake_production => (
    is      => 'ro',
    default => 0,
);

has burger_production => (
    is      => 'ro',
    default => 0,
);

has fungus_production => (
    is      => 'ro',
    default => 0,
);

has syrup_production => (
    is      => 'ro',
    default => 0,
);

has algae_production => (
    is      => 'ro',
    default => 0,
);

has meal_production => (
    is      => 'ro',
    default => 0,
);

has milk_production => (
    is      => 'ro',
    default => 0,
);

has pancake_production => (
    is      => 'ro',
    default => 0,
);

has pie_production => (
    is      => 'ro',
    default => 0,
);

has chip_production => (
    is      => 'ro',
    default => 0,
);

has soup_production => (
    is      => 'ro',
    default => 0,
);

has bread_production => (
    is      => 'ro',
    default => 0,
);

has wheat_production => (
    is      => 'ro',
    default => 0,
);

has cider_production => (
    is      => 'ro',
    default => 0,
);

has corn_production => (
    is      => 'ro',
    default => 0,
);

has root_production => (
    is      => 'ro',
    default => 0,
);

has bean_production => (
    is      => 'ro',
    default => 0,
);

has cheese_production => (
    is      => 'ro',
    default => 0,
);

has apple_production => (
    is      => 'ro',
    default => 0,
);

has lapis_production => (
    is      => 'ro',
    default => 0,
);

has potato_production => (
    is      => 'ro',
    default => 0,
);

has ore_production => (
    is      => 'ro',
    default => 0,
);

has water_storage => (
    is      => 'ro',
    default => 0,
);

has energy_storage => (
    is      => 'ro',
    default => 0,
);

has food_storage => (
    is      => 'ro',
    default => 0,
);

has ore_storage => (
    is      => 'ro',
    default => 0,
);

has waste_storage => (
    is      => 'ro',
    default => 0,
);

# BASE FORMULAS

sub production_hour {
    return (GROWTH ** ( $_[0]->level - 1));
}

sub upgrade_cost {
    return (INFLATION ** $_[0]->level);
}

sub consumption_hour {
    $_[0]->production_hour;
}

# PRODUCTION

sub lapis_production_hour {
    my ($self) = @_;
    return $self->lapis_production * $self->production_hour;
}

sub potato_production_hour {
    my ($self) = @_;
    return $self->potato_production * $self->production_hour;
}

sub bean_production_hour {
    my ($self) = @_;
    return $self->bean_production * $self->production_hour;
}

sub cheese_production_hour {
    my ($self) = @_;
    return $self->cheese_production * $self->production_hour;
}

sub apple_production_hour {
    my ($self) = @_;
    return $self->apple_production * $self->production_hour;
}

sub root_production_hour {
    my ($self) = @_;
    return $self->root_production * $self->production_hour;
}

sub corn_production_hour {
    my ($self) = @_;
    return $self->corn_production * $self->production_hour;
}

sub cider_production_hour {
    my ($self) = @_;
    return $self->cider_production * $self->production_hour;
}

sub wheat_production_hour {
    my ($self) = @_;
    return $self->wheat_production * $self->production_hour;
}

sub bread_production_hour {
    my ($self) = @_;
    return $self->bread_production * $self->production_hour;
}

sub soup_production_hour {
    my ($self) = @_;
    return $self->soup_production * $self->production_hour;
}

sub chip_production_hour {
    my ($self) = @_;
    return $self->chip_production * $self->production_hour;
}

sub pie_production_hour {
    my ($self) = @_;
    return $self->pie_production * $self->production_hour;
}

sub pancake_production_hour {
    my ($self) = @_;
    return $self->pancake_production * $self->production_hour;
}

sub milk_production_hour {
    my ($self) = @_;
    return $self->milk_production * $self->production_hour;
}

sub meal_production_hour {
    my ($self) = @_;
    return $self->meal_production * $self->production_hour;
}

sub algae_production_hour {
    my ($self) = @_;
    return $self->algae_production * $self->production_hour;
}

sub syrup_production_hour {
    my ($self) = @_;
    return $self->syrup_production * $self->production_hour;
}

sub fungus_production_hour {
    my ($self) = @_;
    return $self->fungus_production * $self->production_hour;
}

sub burger_production_hour {
    my ($self) = @_;
    return $self->burger_production * $self->production_hour;
}

sub shake_production_hour {
    my ($self) = @_;
    return $self->shake_production * $self->production_hour;
}

sub beetle_production_hour {
    my ($self) = @_;
    return $self->beetle_production * $self->production_hour;
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
    return $self->food_consumption * $self->consumption_hour;
}

sub food_hour {
    my ($self) = @_;
    return $self->food_production_hour - $self->food_consumption_hour;
}

sub energy_production_hour {
    my ($self) = @_;
    return $self->energy_production * $self->production_hour;
}

sub energy_consumption_hour {
    my ($self) = @_;
    return $self->energy_consumption * $self->consumption_hour;
}

sub energy_hour {
    my ($self) = @_;
    return $self->energy_production_hour - $self->energy_consumption_hour;
}

sub rutile_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->rutile / 100);
}

sub chromite_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->chromite / 100);
}

sub chalcopyrite_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->chalcopyrite / 100);
}

sub galena_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->galena / 100);
}

sub gold_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->gold / 100);
}

sub uraninite_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->uraninite / 100);
}

sub bauxite_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->bauxite / 100);
}

sub limonite_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->limonite / 100);
}

sub halite_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->halite / 100);
}

sub gypsum_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->gypsum / 100);
}

sub trona_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->trona / 100);
}

sub kerogen_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->kerogen / 100);
}

sub petroleum_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->petroleum / 100);
}

sub anthracite_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->anthracite / 100);
}

sub sulfate_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->sulfate / 100);
}

sub zircon_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->zircon / 100);
}

sub monazite_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->monazite / 100);
}

sub fluorite_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->fluorite / 100);
}

sub beryl_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->beryl / 100);
}

sub magnetite_production_hour {
    my ($self, $body) = @_;
    $body ||= $self->body;
    return $self->ore_production * $self->production_hour / ($body->magnetite / 100);
}

sub ore_production_hour {
    my ($self) = @_;
    my $tally = 0;
    my $body = $self->body;
    foreach my $ore (ORE_TYPES) {
        my $method = $ore."_production_hour";
        $tally += $self->$method($body);
    }
    return $tally;
}

sub ore_consumption_hour {
    my ($self) = @_;
    return $self->ore_consumption * $self->consumption_hour;
}

sub ore_hour {
    my ($self) = @_;
    return $self->ore_production_hour - $self->ore_consumption_hour;
}

sub water_production_hour {
    my ($self) = @_;
    my $body = $self->body;
    return $self->water_production * $self->production_hour / ($body->water / 100);
}

sub water_consumption_hour {
    my ($self) = @_;
    return $self->water_consumption * $self->consumption_hour;
}

sub water_hour {
    my ($self) = @_;
    return $self->water_production_hour - $self->water_consumption_hour;
}

sub waste_production_hour {
    my ($self) = @_;
    return $self->waste_production * $self->production_hour;
}

sub waste_consumption_hour {
    my ($self) = @_;
    return $self->waste_consumption * $self->consumption_hour;
}

sub waste_hour {
    my ($self) = @_;
    return $self->waste_production_hour - $self->energy_consumption_hour;
}

sub happiness_production_hour {
    my ($self) = @_;
    return $self->happiness_production * $self->production_hour;
}

sub happiness_consumption_hour {
    my ($self) = @_;
    return $self->happiness_consumption * $self->consumption_hour;
}

sub happiness_hour {
    my ($self) = @_;
    return $self->happiness_production_hour - $self->energy_consumption_hour;
}

# STORAGE

sub food_storage_capacity {
    my ($self) = @_;
    return $self->food_storage * $self->production_hour;
}

sub energy_storage_capacity {
    my ($self) = @_;
    return $self->energy_storage * $self->production_hour;
}

sub ore_storage_capacity {
    my ($self) = @_;
    return $self->ore_storage * $self->production_hour;
}

sub water_storage_capacity {
    my ($self) = @_;
    return $self->water_storage * $self->production_hour;
}

sub waste_storage_capacity {
    my ($self) = @_;
    return $self->waste_storage * $self->production_hour;
}

# BUILD

sub check_build_prereqs {
    my ($self, $body) = @_;
    my $db = $self->simpledb;
    my $prereqs = $self->building_prereq;
    foreach my $key (keys %{$prereqs}) {
        my $count = $db->domain($key)->count({body_id=>$body->id, level=>['>=',$prereqs->{$key}]});
        if ($count < 1) {
            confess [1013, "You don't have the necessary prerequisite buildings.",[$key, $prereqs->{$key}]];
        }
    }
    return 1;
}



# UPGRADES

sub has_met_upgrade_prereqs {
    return 1;
}

sub has_pending_build {
    my ($self) = @_;
    my $queue = $self->build_queue;
    return (defined $queue && $queue->is_complete($self)) ? 1 : 0;
}

sub can_upgrade {
    my ($self, $cost) = @_;
    my $body = $self->body;
    $body->recalc_stats;
    return $body->has_resources_to_build($cost)
        && $body->has_resources_to_operate()
        && $self->has_met_upgrade_prereqs()
        && ! $self->has_pending_build();    
}

sub cost_to_upgrade {
    my ($self) = @_;
    my $upgrade_cost = $self->upgrade_cost;
    return {
        food    => $self->food_to_build * $upgrade_cost,
        energy  => $self->energy_to_build * $upgrade_cost,
        ore     => $self->ore_to_build * $upgrade_cost,
        water   => $self->water_to_build * $upgrade_cost,
        waste   => $self->waste_to_build * $upgrade_cost,
        'time'  => $self->time_to_build * $upgrade_cost,
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
    });
    $self->build_queue_id($queue->id);
    $self->put;

}

sub finish_upgrade {
    my ($self) = @_;
    $self->level($self->level + 1);
    $self->build_queue_id('');
    $self->put;
    $self->body->recalc_stats;
}

no Moose;
__PACKAGE__->meta->make_immutable;
