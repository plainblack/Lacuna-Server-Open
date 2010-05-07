package Lacuna::DB::Result::Building;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Constants ':all';
use List::Util qw(shuffle);
use Lacuna::Util qw(format_date to_seconds);

__PACKAGE__->load_components('DynamicSubclass');
__PACKAGE__->table('building');
__PACKAGE__->add_columns(
    date_created    => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    body_id         => { data_type => 'int', size => 11, is_nullable => 0 },
    x               => { data_type => 'int', size => 11, default_value => 0 },
    y               => { data_type => 'int', size => 11, default_value => 0 },
    level           => { data_type => 'int', size => 11, default_value => 0 },
    class           => { data_type => 'char', size => 255, is_nullable => 0 },
    offline         => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    upgrade_started => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    upgrade_ends    => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    is_upgrading    => { data_type => 'int', size => 1, default => 0 },
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Body', 'body_id');
__PACKAGE__->typecast_map(class => {
    'Lacuna::DB::Result::Building::Development' => 'Lacuna::DB::Result::Building::Development',
    'Lacuna::DB::Result::Building::Embassy' => 'Lacuna::DB::Result::Building::Embassy',
    'Lacuna::DB::Result::Building::EntertainmentDistrict' => 'Lacuna::DB::Result::Building::EntertainmentDistrict',
    'Lacuna::DB::Result::Building::Espionage' => 'Lacuna::DB::Result::Building::Espionage',
    'Lacuna::DB::Result::Building::Food' => 'Lacuna::DB::Result::Building::Food',
    'Lacuna::DB::Result::Building::GasGiantLab' => 'Lacuna::DB::Result::Building::GasGiantLab',
    'Lacuna::DB::Result::Building::Intelligence' => 'Lacuna::DB::Result::Building::Intelligence',
    'Lacuna::DB::Result::Building::Network19' => 'Lacuna::DB::Result::Building::Network19',
    'Lacuna::DB::Result::Building::Observatory' => 'Lacuna::DB::Result::Building::Observatory',
    'Lacuna::DB::Result::Building::Park' => 'Lacuna::DB::Result::Building::Park',
    'Lacuna::DB::Result::Building::PlanetaryCommand' => 'Lacuna::DB::Result::Building::PlanetaryCommand',
    'Lacuna::DB::Result::Building::Propulsion' => 'Lacuna::DB::Result::Building::Propulsion',
    'Lacuna::DB::Result::Building::RND' => 'Lacuna::DB::Result::Building::RND',
    'Lacuna::DB::Result::Building::Security' => 'Lacuna::DB::Result::Building::Security',
    'Lacuna::DB::Result::Building::Shipyard' => 'Lacuna::DB::Result::Building::Shipyard',
    'Lacuna::DB::Result::Building::SpacePort' => 'Lacuna::DB::Result::Building::SpacePort',
    'Lacuna::DB::Result::Building::TerraformingLab' => 'Lacuna::DB::Result::Building::TerraformingLab',
    'Lacuna::DB::Result::Building::Trade' => 'Lacuna::DB::Result::Building::Trade',
    'Lacuna::DB::Result::Building::Transporter' => 'Lacuna::DB::Result::Building::Transporter',
    'Lacuna::DB::Result::Building::University' => 'Lacuna::DB::Result::Building::University',
    'Lacuna::DB::Result::Building::Water::Production' => 'Lacuna::DB::Result::Building::Water::Production',
    'Lacuna::DB::Result::Building::Water::Purification' => 'Lacuna::DB::Result::Building::Water::Purification',
    'Lacuna::DB::Result::Building::Water::Reclamation' => 'Lacuna::DB::Result::Building::Water::Reclamation',
    'Lacuna::DB::Result::Building::Water::Storage' => 'Lacuna::DB::Result::Building::Water::Storage',
    'Lacuna::DB::Result::Building::Waste::Recycling' => 'Lacuna::DB::Result::Building::Waste::Recycling',
    'Lacuna::DB::Result::Building::Waste::Sequestration' => 'Lacuna::DB::Result::Building::Waste::Sequestration',
    'Lacuna::DB::Result::Building::Waste::Treatment' => 'Lacuna::DB::Result::Building::Waste::Treatment',
    'Lacuna::DB::Result::Building::Permanent::Crater' => 'Lacuna::DB::Result::Building::Permanent::Crater',
    'Lacuna::DB::Result::Building::Permanent::GasGiantPlatform' => 'Lacuna::DB::Result::Building::Permanent::GasGiantPlatform',
    'Lacuna::DB::Result::Building::Permanent::Lake' => 'Lacuna::DB::Result::Building::Permanent::Lake',
    'Lacuna::DB::Result::Building::Permanent::RockyOutcrop' => 'Lacuna::DB::Result::Building::Permanent::RockyOutcrop',
    'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform' => 'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform',
    'Lacuna::DB::Result::Building::Ore::Mine' => 'Lacuna::DB::Result::Building::Ore::Mine',
    'Lacuna::DB::Result::Building::Ore::Ministry' => 'Lacuna::DB::Result::Building::Ore::Ministry',
    'Lacuna::DB::Result::Building::Ore::Platform' => 'Lacuna::DB::Result::Building::Ore::Platform',
    'Lacuna::DB::Result::Building::Ore::Refinery' => 'Lacuna::DB::Result::Building::Ore::Refinery',
    'Lacuna::DB::Result::Building::Ore::Storage' => 'Lacuna::DB::Result::Building::Ore::Storage',
    'Lacuna::DB::Result::Building::Food::Reserve' => 'Lacuna::DB::Result::Building::Food::Reserve',
    'Lacuna::DB::Result::Building::Food::Factory::Bread' => 'Lacuna::DB::Result::Building::Food::Factory::Bread',
    'Lacuna::DB::Result::Building::Food::Factory::Burger' => 'Lacuna::DB::Result::Building::Food::Factory::Burger',
    'Lacuna::DB::Result::Building::Food::Factory::Cheese' => 'Lacuna::DB::Result::Building::Food::Factory::Cheese',
    'Lacuna::DB::Result::Building::Food::Factory::Chip' => 'Lacuna::DB::Result::Building::Food::Factory::Chip',
    'Lacuna::DB::Result::Building::Food::Factory::Cider' => 'Lacuna::DB::Result::Building::Food::Factory::Cider',
    'Lacuna::DB::Result::Building::Food::Factory::CornMeal' => 'Lacuna::DB::Result::Building::Food::Factory::CornMeal',
    'Lacuna::DB::Result::Building::Food::Factory::Pancake' => 'Lacuna::DB::Result::Building::Food::Factory::Pancake',
    'Lacuna::DB::Result::Building::Food::Factory::Pie' => 'Lacuna::DB::Result::Building::Food::Factory::Pie',
    'Lacuna::DB::Result::Building::Food::Factory::Shake' => 'Lacuna::DB::Result::Building::Food::Factory::Shake',
    'Lacuna::DB::Result::Building::Food::Factory::Soup' => 'Lacuna::DB::Result::Building::Food::Factory::Soup',
    'Lacuna::DB::Result::Building::Food::Factory::Syrup' => 'Lacuna::DB::Result::Building::Food::Factory::Syrup',
    'Lacuna::DB::Result::Building::Food::Farm::Algae' => 'Lacuna::DB::Result::Building::Food::Farm::Algae',
    'Lacuna::DB::Result::Building::Food::Farm::Apple' => 'Lacuna::DB::Result::Building::Food::Farm::Apple',
    'Lacuna::DB::Result::Building::Food::Farm::Beeldeban' => 'Lacuna::DB::Result::Building::Food::Farm::Beeldeban',
    'Lacuna::DB::Result::Building::Food::Farm::Bean' => 'Lacuna::DB::Result::Building::Food::Farm::Bean',
    'Lacuna::DB::Result::Building::Food::Farm::Corn' => 'Lacuna::DB::Result::Building::Food::Farm::Corn',
    'Lacuna::DB::Result::Building::Food::Farm::Dairy' => 'Lacuna::DB::Result::Building::Food::Farm::Dairy',
    'Lacuna::DB::Result::Building::Food::Farm::Lapis' => 'Lacuna::DB::Result::Building::Food::Farm::Lapis',
    'Lacuna::DB::Result::Building::Food::Farm::Malcud' => 'Lacuna::DB::Result::Building::Food::Farm::Malcud',
    'Lacuna::DB::Result::Building::Food::Farm::Potato' => 'Lacuna::DB::Result::Building::Food::Farm::Potato',
    'Lacuna::DB::Result::Building::Food::Farm::Root' => 'Lacuna::DB::Result::Building::Food::Farm::Root',
    'Lacuna::DB::Result::Building::Food::Farm::Wheat' => 'Lacuna::DB::Result::Building::Food::Farm::Wheat',
    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Fission',
    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Fusion',
    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Geo',
    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Hydrocarbon',
    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Reserve',
    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Singularity',
    'Lacuna::DB::Result::Building::Energy::' => 'Lacuna::DB::Result::Building::Energy::Waste',
});

sub controller_class {
    confess "you need to override me";
}

sub is_offline {
    my $self = shift;
    if ($self->offline > DateTime->now) {
        confess [1013, $self->name.' is currently offline.'];
    }
}

use constant max_instances_per_planet => 9999999;

use constant university_prereq => 0;

sub build_tags {
    return ();  
}

use constant min_orbit => 1;

use constant max_orbit => 7;

use constant building_prereq => {};

use constant name => 'Building';

sub image {
    confess 'override me';
}

sub image_level {
    my ($self, $level) = @_;
    $level ||= $self->level;
    $level = ($level > 9) ? 9 : $level;
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
    return $_[0]->production_hour;
}

# PRODUCTION

sub farming_production_bonus {
    my ($self) = @_;
    my $empire = $self->body->empire;
    my $boost = (DateTime->now < $empire->food_boost) ? 25 : 0;
    return (100 + $boost + $empire->species->farming_affinity * 3) / 100;
}

sub manufacturing_production_bonus {
    my ($self) = @_;
    my $empire = $self->body->empire;
    return (100 + $empire->species->manufacturing_affinity * 3) / 100;
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
    return sprintf('%.0f',$self->cheese_production * $self->production_hour * $self->manufacturing_production_bonus);
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
    return sprintf('%.0f',$self->cider_production * $self->production_hour * $self->manufacturing_production_bonus);
}

sub wheat_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->wheat_production * $self->production_hour * $self->farming_production_bonus);
}

sub bread_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->bread_production * $self->production_hour * $self->manufacturing_production_bonus);
}

sub soup_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->soup_production * $self->production_hour * $self->manufacturing_production_bonus);
}

sub chip_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->chip_production * $self->production_hour * $self->manufacturing_production_bonus);
}

sub pie_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->pie_production * $self->production_hour * $self->manufacturing_production_bonus);
}

sub pancake_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->pancake_production * $self->production_hour * $self->manufacturing_production_bonus);
}

sub milk_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->milk_production * $self->production_hour * $self->farming_production_bonus);
}

sub meal_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->meal_production * $self->production_hour * $self->manufacturing_production_bonus);
}

sub algae_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->algae_production * $self->production_hour * $self->farming_production_bonus);
}

sub syrup_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->syrup_production * $self->production_hour * $self->manufacturing_production_bonus);
}

sub fungus_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->fungus_production * $self->production_hour * $self->farming_production_bonus);
}

sub burger_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->burger_production * $self->production_hour * $self->manufacturing_production_bonus);
}

sub shake_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->shake_production * $self->production_hour * $self->manufacturing_production_bonus);
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
    my $empire = $self->body->empire;
    my $boost = (DateTime->now < $empire->energy_boost) ? 25 : 0;
    return (100 + $boost + $empire->species->science_affinity * 3) / 100;
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
    my $refinery = $self->body->refinery;
    my $refinery_bonus = (defined $refinery) ? $refinery->level * 5 : 0;
    my $empire = $self->body->empire;
    my $boost = (DateTime->now < $empire->ore_boost) ? 25 : 0;
    return (100 + $boost + $refinery_bonus + $empire->species->mining_affinity * 3) / 100;
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
    my $empire = $self->body->empire;
    my $boost = (DateTime->now < $empire->water_boost) ? 25 : 0;
    return (100 + $boost + $empire->species->environmental_affinity * 3) / 100;
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
    return (100 + $self->body->empire->species->environmental_affinity) / 100;
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
    my $empire = $self->body->empire;
    my $boost = (DateTime->now < $empire->happiness_boost) ? 25 : 0;
    return (100 + $boost + ($empire->species->political_affinity * 6)) / 100;
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
    return sprintf('%.0f',$self->happiness_production_hour - $self->happiness_consumption_hour);
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
        confess [1013, "Can't build a building outside of it's Goldilox zone.", [$self->min_orbit, $self->max_orbit]];
    }
    
    unless ($self->has_free_build) {
        # check university level
        if ($self->university_prereq > $body->empire->university_level) {
            confess [1013, "University research too low.",$self->university_prereq];
        }
    
        # check building prereqs
        my $buildings = Lacuna->db->resultset('Lacuna::DB::Result::Building');
        my $prereqs = $self->building_prereq;
        foreach my $key (keys %{$prereqs}) {
            my $count = $buildings->search({body_id=>$body->id, class=>$key, level=>{'>=',$prereqs->{$key}}});
            if ($count < 1) {
                confess [1013, "You don't have the necessary prerequisite buildings.",[$key->name, $prereqs->{$key}]];
            }
        }
    }
    
    return 1;
}



# UPGRADES

sub upgrade_status {
    my ($self) = @_;
    my $now = DateTime->now;
    my $complete = $self->upgrade_ends;
    if ($self->is_upgrading) {
        return undef;
    }
    else {
        return {
            seconds_remaining   => to_seconds($complete - $now),
            start               => format_date($self->upgrade_started),
            end                 => format_date($self->upgrade_ends),
        };
    }
}

sub has_met_upgrade_prereqs {
    my ($self) = @_;
    if (!$self->isa('Lacuna::DB::Result::Building::University') && $self->level >= $self->body->empire->university_level + 1) {
        confess [1013, "You cannot upgrade a building past your university level."];
    }
    return 1;
}

sub has_no_pending_build {
    my ($self) = @_;
    if ($self->is_upgrading) {
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
    $self->has_met_upgrade_prereqs;
    $self->has_no_pending_build;
    $body->has_room_in_build_queue;
    return 1;
}

sub construction_cost_reduction_bonus {
    my $self = shift;
    return (100 - $self->body->empire->species->research_affinity) / 100
}

sub manufacturing_cost_reduction_bonus {
    my $self = shift;
    return (100 - $self->body->empire->species->manufacturing_affinity) / 100
}

sub time_cost_reduction_bonus {
    my ($self, $extra) = @_;
    $extra ||= 0;
    return (100 - $extra - $self->body->empire->species->management_affinity) / 100
}

sub has_free_build {
    my $self = shift;
    return ($self->level == 0 && $self->body->get_freebie($self->class) == 1) ? 1 : 0;
}

sub has_free_upgrade {
    my $self = shift;
    return ($self->body->get_freebie($self->class) == $self->level + 1) ? 1 : 0;
}

sub cost_to_upgrade {
    my ($self) = @_;
    my $upgrade_cost = $self->upgrade_cost;
    my $upgrade_cost_reduction = $self->construction_cost_reduction_bonus;
    if ($self->has_free_build) { # gets a free building
        $upgrade_cost_reduction = 0;
    }
    elsif ($self->has_free_upgrade) { # gets a free upgrade
        $upgrade_cost_reduction = 0;
    }
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
    my %stats;
    my @list = qw(food_hour food_capacity ore_hour ore_capacity water_hour water_capacity waste_hour waste_capacity energy_hour energy_capacity happiness_hour);
    foreach my $resource (@list) {
        $stats{$resource} = $self->$resource;
    }
    $self->level($current_level);
    return \%stats;
}

sub lock_upgrade {
    my ($self, $x, $y) = @_;
    return Lacuna->cache->set('upgrade_contention_lock', $self->id,{locked=>$self->level + 1}, 30); # lock it
}

sub is_upgrade_locked {
    my ($self, $x, $y) = @_;
    return eval{Lacuna->cache->get('upgrade_contention_lock', $self->id)->{locked}};
}

sub start_upgrade {
    my ($self, $cost) = @_;  
    my $body = $self->body;
    $cost ||= $self->cost_to_upgrade;
    
    # set time to build, plus what's in the queue
    my $time_to_build = $body->get_existing_build_queue_time->add(seconds=>$cost->{time});
    
    # add to queue
    $self->update({
        is_upgrading    => 1,
        upgrade_started => DateTime->now,
        upgrade_ends    => $time_to_build,
    });
    
    # clear cache
    $body->clear_last_in_build_queue;

    $self->body->empire->trigger_full_update;
}

sub finish_upgrade {
    my ($self) = @_;
    my $body = $self->body;    
    $self->level($self->level + 1);
    $self->update;
    $body->clear_last_in_build_queue;
    $body->needs_recalc(1);
    $body->update;
    my $empire = $body->empire; 
    $empire->trigger_full_update;
    $empire->add_medal('building'.$self->level);
    my $type = $self->controller_class;
    $type =~ s/^Lacuna::Building::(\w+)$/$1/;
    $empire->add_medal($type);
    if ($self->level % 5 == 0) {
        my %levels = (5=>'a quiet',10=>'an extravagant',15=>'a lavish',20=>'a magnificent',25=>'a historic',30=>'an epic',35=>'a miraculous',40=>'a magical');
        $self->body->add_news($self->level*5,"In %s ceremony, %s unveiled it's newly augmentented %s.", $levels{$self->level}, $empire->name, $self->name);
    }
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
