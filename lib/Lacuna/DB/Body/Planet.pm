package Lacuna::DB::Body::Planet;

use Moose;
extends 'Lacuna::DB::Body';
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use List::Util qw(shuffle);

__PACKAGE__->add_attributes(
    size                    => { isa => 'Int' },
    empire_id               => { isa => 'Str', default=>'None' },
    building_count          => { isa => 'Int', default=>0 },
    happiness_per           => { isa => 'Int', default=>0 },
    happiness               => { isa => 'Int', default=>0 },
    waste_per               => { isa => 'Int', default=>0 },
    waste_stored            => { isa => 'Int', default=>0 },
    waste_storage           => { isa => 'Int', default=>0 },
    energy_per              => { isa => 'Int', default=>0 },
    energy_stored           => { isa => 'Int', default=>0 },
    energy_storage          => { isa => 'Int', default=>0 },
    water_per               => { isa => 'Int', default=>0 },
    water_stored            => { isa => 'Int', default=>0 },
    water_storage           => { isa => 'Int', default=>0 },
    ore_storage             => { isa => 'Int', default=>0 },
    rutile_stored           => { isa => 'Int', default=>0 },
    chromite_stored         => { isa => 'Int', default=>0 },
    chalcopyrite_stored     => { isa => 'Int', default=>0 },
    galena_stored           => { isa => 'Int', default=>0 },
    gold_stored             => { isa => 'Int', default=>0 },
    uraninite_stored        => { isa => 'Int', default=>0 },
    bauxite_stored          => { isa => 'Int', default=>0 },
    limonite_stored         => { isa => 'Int', default=>0 },
    halite_stored           => { isa => 'Int', default=>0 },
    gypsum_stored           => { isa => 'Int', default=>0 },
    trona_stored            => { isa => 'Int', default=>0 },
    kerogen_stored          => { isa => 'Int', default=>0 },
    petroleum_stored        => { isa => 'Int', default=>0 },
    anthracite_stored       => { isa => 'Int', default=>0 },
    sulfate_stored          => { isa => 'Int', default=>0 },
    zircon_stored           => { isa => 'Int', default=>0 },
    monazite_stored         => { isa => 'Int', default=>0 },
    fluorite_stored         => { isa => 'Int', default=>0 },
    beryl_stored            => { isa => 'Int', default=>0 },
    magnetite_stored        => { isa => 'Int', default=>0 },
    rutile_hour         => { isa => 'Int', default=>0 },
    chromite_hour       => { isa => 'Int', default=>0 },
    chalcopyrite_hour   => { isa => 'Int', default=>0 },
    galena_hour         => { isa => 'Int', default=>0 },
    gold_hour           => { isa => 'Int', default=>0 },
    uraninite_hour      => { isa => 'Int', default=>0 },
    bauxite_hour        => { isa => 'Int', default=>0 },
    limonite_hour       => { isa => 'Int', default=>0 },
    halite_hour         => { isa => 'Int', default=>0 },
    gypsum_hour         => { isa => 'Int', default=>0 },
    trona_hour          => { isa => 'Int', default=>0 },
    kerogen_hour        => { isa => 'Int', default=>0 },
    petroleum_hour      => { isa => 'Int', default=>0 },
    anthracite_hour     => { isa => 'Int', default=>0 },
    sulfate_hour        => { isa => 'Int', default=>0 },
    zircon_hour         => { isa => 'Int', default=>0 },
    monazite_hour       => { isa => 'Int', default=>0 },
    fluorite_hour       => { isa => 'Int', default=>0 },
    beryl_hour          => { isa => 'Int', default=>0 },
    magnetite_hour      => { isa => 'Int', default=>0 },
    food_storage            => { isa => 'Int', default=>0 },
    lapis_hour          => { isa => 'Int', default=>0 },
    potato_hour         => { isa => 'Int', default=>0 },
    apple_hour          => { isa => 'Int', default=>0 },
    root_hour           => { isa => 'Int', default=>0 },
    corn_hour           => { isa => 'Int', default=>0 },
    cider_hour          => { isa => 'Int', default=>0 },
    wheat_hour          => { isa => 'Int', default=>0 },
    bread_hour          => { isa => 'Int', default=>0 },
    soup_hour           => { isa => 'Int', default=>0 },
    chip_hour           => { isa => 'Int', default=>0 },
    pie_hour            => { isa => 'Int', default=>0 },
    pancake_hour        => { isa => 'Int', default=>0 },
    milk_hour           => { isa => 'Int', default=>0 },
    meal_hour           => { isa => 'Int', default=>0 },
    algae_hour          => { isa => 'Int', default=>0 },
    syrup_hour          => { isa => 'Int', default=>0 },
    fungus_hour         => { isa => 'Int', default=>0 },
    burger_hour         => { isa => 'Int', default=>0 },
    shake_hour          => { isa => 'Int', default=>0 },
    beetle_hour         => { isa => 'Int', default=>0 },
    lapis_stored            => { isa => 'Int', default=>0 },
    potato_stored           => { isa => 'Int', default=>0 },
    apple_stored            => { isa => 'Int', default=>0 },
    root_stored             => { isa => 'Int', default=>0 },
    corn_stored             => { isa => 'Int', default=>0 },
    cider_stored            => { isa => 'Int', default=>0 },
    wheat_stored            => { isa => 'Int', default=>0 },
    bread_stored            => { isa => 'Int', default=>0 },
    soup_stored             => { isa => 'Int', default=>0 },
    chip_stored             => { isa => 'Int', default=>0 },
    pie_stored              => { isa => 'Int', default=>0 },
    pancake_stored          => { isa => 'Int', default=>0 },
    milk_stored             => { isa => 'Int', default=>0 },
    meal_stored             => { isa => 'Int', default=>0 },
    algae_stored            => { isa => 'Int', default=>0 },
    syrup_stored            => { isa => 'Int', default=>0 },
    fungus_stored           => { isa => 'Int', default=>0 },
    burger_stored           => { isa => 'Int', default=>0 },
    shake_stored            => { isa => 'Int', default=>0 },
    beetle_stored           => { isa => 'Int', default=>0 },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');
__PACKAGE__->has_many('regular_buildings','Lacuna::DB::Building','body_id');
__PACKAGE__->has_many('food_buildings','Lacuna::DB::Building::Food','body_id');
__PACKAGE__->has_many('water_buildings','Lacuna::DB::Building::Water','body_id');
__PACKAGE__->has_many('waste_buildings','Lacuna::DB::Building::Waste','body_id');
__PACKAGE__->has_many('ore_buildings','Lacuna::DB::Building::Ore','body_id');
__PACKAGE__->has_many('energy_buildings','Lacuna::DB::Building::Energy','body_id');
__PACKAGE__->has_many('permanent_buildings','Lacuna::DB::Building::Permanent','body_id');


# BUILDINGS

sub buildings {
    my $self = shift;
    return (
        $self->regular_buildings,
        $self->food_buildings,
        $self->water_buildings,
        $self->energy_buildings,
        $self->ore_buildings,
        $self->waste_buildings,
        $self->permanent_buildings,
        );
}

sub is_space_free {
    my ($self, $x, $y) = @_;
    my $db = $self->simpledb;
    foreach my $domain (qw(building energy water food waste ore permanent)) {
        my $count = $db->domain($domain)->count({
            body_id => $self->id,
            x       => $x,
            y       => $y,
        });
        return 0 if $count > 0;
    }
    return 1;
}

sub can_build_building {
    my ($self, $building) = @_;

    # check for space
    if ($building->x < 5 || $building->x > -5 || $building->y > 5 || $building->y < -5) {
        confess [1009, "That's not a valid space for a building.", [$building->x, $building->y]];
    }
    if (self->building_count >= $self->size) {
        confess [1009, "You've already reached the maximum number of buildings for this planet.", $self->size];
    }
    unless ($self->is_space_free($building->x, $building->y)) {
        confess [1009, "That space is already occupied.", [$building->x,$building->y]]; 
    }
    
    # has building prereqs
    if ($building->university_prereq < $self->empire->university_level) {
        confess [1013, "University research too low.",$building->university_prereq];
    }
    $building->check_build_prereqs($self);

    # check available resources
    $self->recalc_stats;
    $self->has_resources_to_build($building);
    $self->has_resources_to_operate($building);
    
    return 1;
}

sub has_resources_to_operate {
    my ($self, $building) = @_;
    my $after = $building->stats_after_upgrade;
    foreach my $resource (qw(food energy ore water)) {
        my $method = $resource.'_hour';
        if ($self->$method  - ($after->{$method} - $building->$method) < 0) {
            confess [1012, "Unsustainable. Not enough resources being produced to build this.", $resource];
        }
    }
    return 1;
}

sub build_building {
    my ($self, $building) = @_;
    
    $self->building_count($self->building_count + 1);
    $self->put;

    # add to build queue
    my $queue = $self->simpledb->domain('build_queue')->insert({
        date_created        => DateTime->now,
        date_complete       => DateTime->now->add(seconds=>$building->time_to_build),
        building_id         => $building->id,
        empire_id           => $self->empire_id,
        building_class      => $building->class,
    });

    # add building placeholder to planet
    $building->build_queue_id($queue->id);
    $building->put;
    
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
    my $count = $self->simpledb->domain($building->class)->count({body_id=>$self->id, class=>$building->class});
    return ($building->max_instances_per_planet > $count) ? 1 : 0;
}


# RESOURCE MANGEMENT

sub add_magnetite {
    my ($self, $value) = @_;
    my $store = $self->magnetite_stored + $value;
    my $storage = $self->magnetite_storage;
    $self->magnetite_stored( ($store < $storage) ? $store : $storage );
}

sub add_beryl {
    my ($self, $value) = @_;
    my $store = $self->beryl_stored + $value;
    my $storage = $self->beryl_storage;
    $self->beryl_stored( ($store < $storage) ? $store : $storage );
}

sub add_fluorite {
    my ($self, $value) = @_;
    my $store = $self->fluorite_stored + $value;
    my $storage = $self->fluorite_storage;
    $self->fluorite_stored( ($store < $storage) ? $store : $storage );
}

sub add_monazite {
    my ($self, $value) = @_;
    my $store = $self->monazite_stored + $value;
    my $storage = $self->monazite_storage;
    $self->monazite_stored( ($store < $storage) ? $store : $storage );
}

sub add_zircon {
    my ($self, $value) = @_;
    my $store = $self->zircon_stored + $value;
    my $storage = $self->zircon_storage;
    $self->zircon_stored( ($store < $storage) ? $store : $storage );
}

sub add_sulfate {
    my ($self, $value) = @_;
    my $store = $self->sulfate_stored + $value;
    my $storage = $self->sulfate_storage;
    $self->sulfate_stored( ($store < $storage) ? $store : $storage );
}

sub add_anthracite {
    my ($self, $value) = @_;
    my $store = $self->anthracite_stored + $value;
    my $storage = $self->anthracite_storage;
    $self->anthracite_stored( ($store < $storage) ? $store : $storage );
}

sub add_petroleum {
    my ($self, $value) = @_;
    my $store = $self->petroleum_stored + $value;
    my $storage = $self->petroleum_storage;
    $self->petroleum_stored( ($store < $storage) ? $store : $storage );
}

sub add_kerogen {
    my ($self, $value) = @_;
    my $store = $self->kerogen_stored + $value;
    my $storage = $self->kerogen_storage;
    $self->kerogen_stored( ($store < $storage) ? $store : $storage );
}

sub add_trona {
    my ($self, $value) = @_;
    my $store = $self->trona_stored + $value;
    my $storage = $self->trona_storage;
    $self->trona_stored( ($store < $storage) ? $store : $storage );
}

sub add_gypsum {
    my ($self, $value) = @_;
    my $store = $self->gypsum_stored + $value;
    my $storage = $self->gypsum_storage;
    $self->gypsum_stored( ($store < $storage) ? $store : $storage );
}

sub add_halite {
    my ($self, $value) = @_;
    my $store = $self->halite_stored + $value;
    my $storage = $self->halite_storage;
    $self->halite_stored( ($store < $storage) ? $store : $storage );
}

sub add_limonite {
    my ($self, $value) = @_;
    my $store = $self->limonite_stored + $value;
    my $storage = $self->limonite_storage;
    $self->limonite_stored( ($store < $storage) ? $store : $storage );
}

sub add_bauxite {
    my ($self, $value) = @_;
    my $store = $self->bauxite_stored + $value;
    my $storage = $self->bauxite_storage;
    $self->bauxite_stored( ($store < $storage) ? $store : $storage );
}

sub add_uraninite {
    my ($self, $value) = @_;
    my $store = $self->uraninite_stored + $value;
    my $storage = $self->uraninite_storage;
    $self->uraninite_stored( ($store < $storage) ? $store : $storage );
}

sub add_gold {
    my ($self, $value) = @_;
    my $store = $self->gold_stored + $value;
    my $storage = $self->gold_storage;
    $self->gold_stored( ($store < $storage) ? $store : $storage );
}

sub add_galena {
    my ($self, $value) = @_;
    my $store = $self->galena_stored + $value;
    my $storage = $self->galena_storage;
    $self->galena_stored( ($store < $storage) ? $store : $storage );
}

sub add_chalcopyrite {
    my ($self, $value) = @_;
    my $store = $self->chalcopyrite_stored + $value;
    my $storage = $self->chalcopyrite_storage;
    $self->chalcopyrite_stored( ($store < $storage) ? $store : $storage );
}

sub add_chromite {
    my ($self, $value) = @_;
    my $store = $self->chromite_stored + $value;
    my $storage = $self->chromite_storage;
    $self->chromite_stored( ($store < $storage) ? $store : $storage );
}

sub add_rutile {
    my ($self, $value) = @_;
    my $store = $self->rutile_stored + $value;
    my $storage = $self->rutile_storage;
    $self->rutile_stored( ($store < $storage) ? $store : $storage );
}

sub spend_ore {
    my ($self, $value) = @_;
    foreach my $type (shuffle ORE_TYPES) {
        my $method = $type."_stored";
        my $stored = $self->method;
        if ($stored > $value) {
            $self->method($stored - $value);
            last;
        }
        else {
            $value -= $stored;
            $self->method(0);
        }
    }
}

sub add_beetle {
    my ($self, $value) = @_;
    my $store = $self->beetle_stored + $value;
    my $storage = $self->beetle_storage;
    $self->beetle_stored( ($store < $storage) ? $store : $storage );
}

sub add_shake {
    my ($self, $value) = @_;
    my $store = $self->shake_stored + $value;
    my $storage = $self->shake_storage;
    $self->shake_stored( ($store < $storage) ? $store : $storage );
}

sub add_burger {
    my ($self, $value) = @_;
    my $store = $self->burger_stored + $value;
    my $storage = $self->burger_storage;
    $self->burger_stored( ($store < $storage) ? $store : $storage );
}

sub add_fungus {
    my ($self, $value) = @_;
    my $store = $self->fungus_stored + $value;
    my $storage = $self->fungus_storage;
    $self->fungus_stored( ($store < $storage) ? $store : $storage );
}

sub add_syrup {
    my ($self, $value) = @_;
    my $store = $self->syrup_stored + $value;
    my $storage = $self->syrup_storage;
    $self->syrup_stored( ($store < $storage) ? $store : $storage );
}

sub add_algae {
    my ($self, $value) = @_;
    my $store = $self->algae_stored + $value;
    my $storage = $self->algae_storage;
    $self->algae_stored( ($store < $storage) ? $store : $storage );
}

sub add_meal {
    my ($self, $value) = @_;
    my $store = $self->meal_stored + $value;
    my $storage = $self->meal_storage;
    $self->meal_stored( ($store < $storage) ? $store : $storage );
}

sub add_milk {
    my ($self, $value) = @_;
    my $store = $self->milk_stored + $value;
    my $storage = $self->milk_storage;
    $self->milk_stored( ($store < $storage) ? $store : $storage );
}

sub add_pancake {
    my ($self, $value) = @_;
    my $store = $self->pancake_stored + $value;
    my $storage = $self->pancake_storage;
    $self->pancake_stored( ($store < $storage) ? $store : $storage );
}

sub add_pie {
    my ($self, $value) = @_;
    my $store = $self->pie_stored + $value;
    my $storage = $self->pie_storage;
    $self->pie_stored( ($store < $storage) ? $store : $storage );
}

sub add_chip {
    my ($self, $value) = @_;
    my $store = $self->chip_stored + $value;
    my $storage = $self->chip_storage;
    $self->chip_stored( ($store < $storage) ? $store : $storage );
}

sub add_soup {
    my ($self, $value) = @_;
    my $store = $self->soup_stored + $value;
    my $storage = $self->soup_storage;
    $self->soup_stored( ($store < $storage) ? $store : $storage );
}

sub add_bread {
    my ($self, $value) = @_;
    my $store = $self->bread_stored + $value;
    my $storage = $self->bread_storage;
    $self->bread_stored( ($store < $storage) ? $store : $storage );
}

sub add_wheat {
    my ($self, $value) = @_;
    my $store = $self->wheat_stored + $value;
    my $storage = $self->wheat_storage;
    $self->wheat_stored( ($store < $storage) ? $store : $storage );
}

sub add_cider {
    my ($self, $value) = @_;
    my $store = $self->cider_stored + $value;
    my $storage = $self->cider_storage;
    $self->cider_stored( ($store < $storage) ? $store : $storage );
}

sub add_corn {
    my ($self, $value) = @_;
    my $store = $self->corn_stored + $value;
    my $storage = $self->corn_storage;
    $self->corn_stored( ($store < $storage) ? $store : $storage );
}

sub add_root {
    my ($self, $value) = @_;
    my $store = $self->root_stored + $value;
    my $storage = $self->root_storage;
    $self->root_stored( ($store < $storage) ? $store : $storage );
}

sub add_apple {
    my ($self, $value) = @_;
    my $store = $self->apple_stored + $value;
    my $storage = $self->apple_storage;
    $self->apple_stored( ($store < $storage) ? $store : $storage );
}

sub add_potato {
    my ($self, $value) = @_;
    my $store = $self->potato_stored + $value;
    my $storage = $self->potato_storage;
    $self->potato_stored( ($store < $storage) ? $store : $storage );
}

sub add_lapis {
    my ($self, $value) = @_;
    my $store = $self->lapis_stored + $value;
    my $storage = $self->lapis_storage;
    $self->lapis_stored( ($store < $storage) ? $store : $storage );
}

sub spend_food {
    my ($self, $value) = @_;
    foreach my $type (shuffle FOOD_TYPES) {
        my $method = $type."_stored";
        my $stored = $self->method;
        if ($stored > $value) {
            $self->method($stored - $value);
            last;
        }
        else {
            $value -= $stored;
            $self->method(0);
        }
    }
}

sub add_energy {
    my ($self, $value) = @_;
    my $store = $self->energy_stored + $value;
    my $storage = $self->energy_storage;
    $self->energy_stored( ($store < $storage) ? $store : $storage );
}

sub spend_energy {
    my ($self, $value) = @_;
    $self->energy_stored( $self->energy_stored - $value );
}

sub add_water {
    my ($self, $value) = @_;
    my $store = $self->water_stored + $value;
    my $storage = $self->water_storage;
    $self->water_stored( ($store < $storage) ? $store : $storage );
}

sub spend_water {
    my ($self, $value) = @_;
    $self->water_stored( $self->water_stored - $value );
}

sub add_happiness {
    my ($self, $value) = @_;
    $self->happiness( $self->happiness + $value );
}

sub spend_happiness {
    my ($self, $value) = @_;
    $self->happiness( $self->happiness - $value );
}

sub add_waste {
    my ($self, $value) = @_;
    my $store = $self->waste_stored + $value;
    my $storage = $self->waste_storage;
    $self->waste_stored( ($store < $storage) ? $store : $storage );
}

sub spend_waste {
    my ($self, $value) = @_;
    $self->waste_stored( $self->waste_stored - $value );
}


no Moose;
__PACKAGE__->meta->make_immutable;
