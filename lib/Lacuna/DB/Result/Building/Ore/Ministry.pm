package Lacuna::DB::Result::Building::Ore::Ministry;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Ore';
use Lacuna::Constants qw(ORE_TYPES GROWTH_F INFLATION_N CONSUME_S WASTE_F);
use POSIX qw(ceil);

use constant prod_rate => GROWTH_F;
use constant consume_rate => CONSUME_S;
use constant cost_rate => INFLATION_N;
use constant waste_prod_rate => WASTE_F;

sub platforms {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->search({ planet_id => $self->body_id });
}

sub ships {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ body_id => $self->body_id, task => 'Mining' });
}

sub max_platforms {
    my $self = shift;
    return ceil($self->effective_level / 2);
}

sub add_ship {
    my ($self, $ship) = @_;
    $ship->task('Mining');
    $ship->update;
    $self->recalc_ore_production;
    return $self;
}

sub send_ship_home {
    my ($self, $asteroid, $ship) = @_;
    $ship->send(
        target      => $asteroid,
        direction   => 'in',
        task        => 'Travelling',
    );
    $self->recalc_ore_production;
    return $self;
}

sub can_add_platform {
    my ($self, $asteroid, $on_arrival) = @_;
    
    # ministry count
    my $count = $self->platforms->count;
    unless ($on_arrival) {
        $count += Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({type=>'mining_platform_ship', task=>'Travelling',body_id=>$self->body_id})->count;
    }    
    if ($count >= $self->max_platforms) {
        confess [1009, 'Already at the maximum number of platforms allowed at this Ministry level.'];
    }
    
    # asteroid count
    $count = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->search({ asteroid_id => $asteroid->id })->count;
    unless ($on_arrival) {
        $count += Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({type=>'mining_platform_ship',foreign_body_id => $asteroid->id, task=>'Travelling',body_id=>$self->body_id})->count;
    }
    if ($asteroid->size <= $count) {
        confess [1010, $asteroid->name.' cannot support any additional mining platforms.'];
    }
    return 1;
}

sub add_platform {
    my ($self, $asteroid) = @_;
    Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->new({
        planet_id   => $self->body_id,
        planet      => $self->body,
        asteroid_id => $asteroid->id,
        asteroid    => $asteroid,
    })->insert;
    $self->recalc_ore_production;
    return $self;
}

sub remove_platform {
    my ($self, $platform) = @_;
    if ($self->platforms->count == 1) {
        my $ships = $self->ships;
        while (my $ship = $ships->next) {
            $self->send_ship_home($platform->asteroid, $ship);
        }
    }
    $platform->delete;
    $self->recalc_ore_production;
    return $self;
}

sub recalc_ore_production {
    my $self = shift;
    my $body = $self->body;
    
    # get ships
    my $ship_speed = 0;
    my $ship_capacity = 0;
    my $ship_count = 0;
    my $ships = $self->ships;
    while (my $ship = $ships->next) {
        $ship_count++;
        $ship_capacity += $ship->hold_size;
        $ship_speed += $ship->speed;
    }
    
    # platforms
    my $platform_count              = $self->platforms->count;
    my $platforms                   = $self->platforms;
    my $production_hour             = 30 * $self->production_hour * $self->mining_production_bonus * $platform_count;
    my $distance = 0;
    while (my $platform = $platforms->next) {
        $distance += $body->calculate_distance_to_target($platform->asteroid);
    }
    $distance *= 2; # gotta go there and back
    $platforms->reset;
    
    # calculate efficiency
    my $trips_per_hour              = $distance ? ($ship_speed / $distance) : 0; 
    my $max_cargo_hauled_per_hour   = $trips_per_hour * $ship_capacity;
    my $cargo_hauled_per_hour       = ($production_hour > $max_cargo_hauled_per_hour) ? $max_cargo_hauled_per_hour : $production_hour;
    my $shipping_capacity           = $max_cargo_hauled_per_hour ? sprintf('%.0f',($production_hour / $max_cargo_hauled_per_hour) * 100) : -1;
    my $cargo_hauled_per_hour_per_platform = $platform_count ? ($cargo_hauled_per_hour / $platform_count) : 0;
    
    # update platforms
    while (my $platform = $platforms->next) {
        my $asteroid                    = $platform->asteroid;
        foreach my $ore (ORE_TYPES) {
            my $hour_method = $ore.'_hour';
            $platform->$hour_method(sprintf('%.0f', $asteroid->$ore * $cargo_hauled_per_hour_per_platform / 10_000));
        }
        $platform->percent_ship_capacity($shipping_capacity);
        $platform->update;
    }
    
    # tell body to recalc at next tick
    $body->needs_recalc(1);
    $body->update;
    return $self;
}

before delete => sub {
    my ($self) = @_;
    $self->ships->update({task=>'Docked'});
    $self->platforms->delete_all;
    $self->body->needs_recalc(1);
    $self->body->update;
};

after finish_upgrade => sub {
    my ($self) = @_;
    $self->recalc_ore_production;
};

before 'can_downgrade' => sub {
    my $self = shift;
    if ($self->platforms->count > ceil(($self->level - 1) / 2)) {
        confess [1013, 'You must abandon one of your Mining Platforms before you can downgrade the Mining Ministry.'];
    }
};

after 'downgrade' => sub {
    my $self = shift;
    $self->recalc_ore_production;
};

use constant controller_class => 'Lacuna::RPC::Building::MiningMinistry';

use constant university_prereq => 12;

use constant max_instances_per_planet => 1;

use constant image => 'miningministry';

use constant name => 'Mining Ministry';

use constant food_to_build => 137;

use constant energy_to_build => 139;

use constant ore_to_build => 137;

use constant water_to_build => 137;

use constant waste_to_build => 70;

use constant time_to_build => 150;

use constant food_consumption => 11;

use constant energy_consumption => 56;

use constant ore_consumption => 8;

use constant water_consumption => 13;

use constant waste_production => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
