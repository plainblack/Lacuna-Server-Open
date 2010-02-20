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

sub controller_class {
    confess "you need to override me";
}

sub max_instances_per_planet {
    return 9999999;
}

sub university_prereq {
    return 0;
}

sub building_prereq {
    return {};
}

sub name {
    return 'Building';
}

sub image {
    confess 'override me';
}

sub time_to_build {
    return 60;
}

sub energy_to_build {
    return 0;
}

sub food_to_build {
    return 0;
}

sub ore_to_build {
    return 0;
}

sub water_to_build {
    return 0;
}

sub waste_to_build {
    return 0;
}

sub happiness_consumption {
    return 0;
}

sub energy_consumption {
    return 0;
}

sub water_consumption {
    return 0;
}

sub waste_consumption {
    return 0;
}

sub food_consumption {
    return 0;
}

sub ore_consumption {
    return 0;
}

sub happiness_production {
    return 0;
}

sub energy_production {
    return 0;
}

sub water_production {
    return 0;
}

sub waste_production {
    return 0;
}

sub beetle_production {
    return 0;
}

sub shake_production {
    return 0;
}

sub burger_production {
    return 0;
}

sub fungus_production {
    return 0;
}

sub syrup_production {
    return 0;
}

sub algae_production {
    return 0;
}

sub meal_production {
    return 0;
}

sub milk_production {
    return 0;
}

sub pancake_production {
    return 0;
}

sub pie_production {
    return 0;
}

sub chip_production {
    return 0;
}

sub soup_production {
    return 0;
}

sub bread_production {
    return 0;
}

sub wheat_production {
    return 0;
}

sub cider_production {
    return 0;
}

sub corn_production {
    return 0;
}

sub root_production {
    return 0;
}

sub bean_production {
    return 0;
}

sub cheese_production {
    return 0;
}

sub apple_production {
    return 0;
}

sub lapis_production {
    return 0;
}

sub potato_production {
    return 0;
}

sub ore_production {
    return 0;
}

sub water_storage {
    return 0;
}

sub energy_storage {
    return 0;
}

sub food_storage {
    return 0;
}

sub ore_storage {
    return 0;
}

sub waste_storage {
    return 0;
}

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
    return sprintf('%.0f',$self->lapis_production * $self->production_hour);
}

sub potato_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->potato_production * $self->production_hour);
}

sub bean_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->bean_production * $self->production_hour);
}

sub cheese_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->cheese_production * $self->production_hour);
}

sub apple_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->apple_production * $self->production_hour);
}

sub root_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->root_production * $self->production_hour);
}

sub corn_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->corn_production * $self->production_hour);
}

sub cider_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->cider_production * $self->production_hour);
}

sub wheat_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->wheat_production * $self->production_hour);
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
    return sprintf('%.0f',$self->milk_production * $self->production_hour);
}

sub meal_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->meal_production * $self->production_hour);
}

sub algae_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->algae_production * $self->production_hour);
}

sub syrup_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->syrup_production * $self->production_hour);
}

sub fungus_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->fungus_production * $self->production_hour);
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
    return sprintf('%.0f',$self->beetle_production * $self->production_hour);
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

sub energy_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->energy_production * $self->production_hour);
}

sub energy_consumption_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->energy_consumption * $self->consumption_hour);
}

sub energy_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->energy_production_hour - $self->energy_consumption_hour);
}

sub ore_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->ore_production * $self->production_hour);
}

sub ore_consumption_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->ore_consumption * $self->consumption_hour);
}

sub ore_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->ore_production_hour - $self->ore_consumption_hour);
}

sub water_production_hour {
    my ($self) = @_;
    return sprintf('%.0f', $self->water_production * $self->production_hour);
}

sub water_consumption_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->water_consumption * $self->consumption_hour);
}

sub water_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->water_production_hour - $self->water_consumption_hour);
}

sub waste_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->waste_production * $self->production_hour);
}

sub waste_consumption_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->waste_consumption * $self->consumption_hour);
}

sub waste_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->waste_production_hour - $self->waste_consumption_hour);
}

sub happiness_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->happiness_production * $self->production_hour);
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
    my $queue = $self->build_queue if ($self->build_queue_id);
    return (defined $queue && $queue->is_complete($self)) ? 1 : 0;
}

sub can_upgrade {
    my ($self, $cost) = @_;
    my $body = $self->body;
    $body->tick;
    return $body->has_resources_to_build($self,$cost)
        && $body->has_resources_to_operate($self)
        && $self->has_met_upgrade_prereqs()
        && ! $self->has_pending_build();    
}

sub cost_to_upgrade {
    my ($self) = @_;
    my $upgrade_cost = $self->upgrade_cost;
    return {
        food    => sprintf('%.0f',$self->food_to_build * $upgrade_cost),
        energy  => sprintf('%.0f',$self->energy_to_build * $upgrade_cost),
        ore     => sprintf('%.0f',$self->ore_to_build * $upgrade_cost),
        water   => sprintf('%.0f',$self->water_to_build * $upgrade_cost),
        waste   => sprintf('%.0f',$self->waste_to_build * $upgrade_cost),
        'time'  => sprintf('%.0f',$self->time_to_build * $upgrade_cost),
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
    $self->build_queue->delete;
    $self->build_queue_id('');
    $self->put;
    $self->body->recalc_stats;
}

no Moose;
__PACKAGE__->meta->make_immutable;
