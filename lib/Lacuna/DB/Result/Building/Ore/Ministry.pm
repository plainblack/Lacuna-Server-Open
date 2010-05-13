package Lacuna::DB::Result::Building::Ore::Ministry;

use Moose;
extends 'Lacuna::DB::Result::Building::Ore';
use Lacuna::Constants qw(ORE_TYPES);

__PACKAGE__->add_columns(
    asteroid_ids                    => { data_type => 'mediumtext', is_nullable => 1, 'serializer_class' => 'JSON' },
    ship_count                      => { data_type => 'int', size => 11, default_value => 0 },
    rutile_hour                     => { data_type => 'int', size => 11, default_value => 0 },
    chromite_hour                   => { data_type => 'int', size => 11, default_value => 0 },
    chalcopyrite_hour               => { data_type => 'int', size => 11, default_value => 0 },
    galena_hour                     => { data_type => 'int', size => 11, default_value => 0 },
    gold_hour                       => { data_type => 'int', size => 11, default_value => 0 },
    uraninite_hour                  => { data_type => 'int', size => 11, default_value => 0 },
    bauxite_hour                    => { data_type => 'int', size => 11, default_value => 0 },
    goethite_hour                   => { data_type => 'int', size => 11, default_value => 0 },
    halite_hour                     => { data_type => 'int', size => 11, default_value => 0 },
    gypsum_hour                     => { data_type => 'int', size => 11, default_value => 0 },
    trona_hour                      => { data_type => 'int', size => 11, default_value => 0 },
    kerogen_hour                    => { data_type => 'int', size => 11, default_value => 0 },
    methane_hour                    => { data_type => 'int', size => 11, default_value => 0 },
    anthracite_hour                 => { data_type => 'int', size => 11, default_value => 0 },
    sulfur_hour                     => { data_type => 'int', size => 11, default_value => 0 },
    zircon_hour                     => { data_type => 'int', size => 11, default_value => 0 },
    monazite_hour                   => { data_type => 'int', size => 11, default_value => 0 },
    fluorite_hour                   => { data_type => 'int', size => 11, default_value => 0 },
    beryl_hour                      => { data_type => 'int', size => 11, default_value => 0 },
    magnetite_hour                  => { data_type => 'int', size => 11, default_value => 0 },
    percent_ship_capacity           => { isa => 'Int', default=>100 },
    percent_platform_capacity       => { isa => 'Int', default=>100 },
);

__PACKAGE__->has_many('platforms', 'Lacuna::DB::Result::MiningPlatforms','ministry_id');

sub ships {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ body_id => $self->body_id, task => 'Mining' });
}

sub max_platforms {
    my $self = shift;
    return $self->level;
}

has platform_production_hour => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return sprintf('%.0f', 70 * $self->production_hour * $self->mining_production_bonus);
    }
);

sub add_ships {
    my ($self, $count) = @_;
    $count ||= 1;
    my $spaceport = $self->body->spaceport;
    foreach (1..$count) {
        $spaceport->remove_ship('cargo_ship');
    }
    $spaceport->save_changed_ports;
    $self->ship_count($self->ship_count + $count);
    $self->recalc_ore_production;
    return $self;
}

sub can_remove_ships {
    my ($self, $count) = @_;
    if ($self->ship_count + $count < 0) {
        confess [1009, 'You do not have that many ships to remove.'];
    }
    return 1;
}

sub send_ships_home {
    my ($self, $asteroid, $count) = @_;
    if ($count >= 0) {
        $self->ship_count($self->ship_count - $count);
        my $date = DateTime->now->add(seconds => $self->calculate_seconds_from_body_to_body('cargo_ship',$asteroid, $self->body));
        foreach (1..$count) {
            Lacuna::DB::Result::TravelQueue->send(
                simpledb    => $self->simpledb,
                date_arrives=> $date,
                body        => $self->body,
                direction   => 'incoming',
                foreign_body=> $asteroid,
            );
        }
        $self->recalc_ore_production;
    }
    return $self;
}

sub can_add_platform {
    my ($self) = @_;
    if ($self->asteroid_count >= $self->max_platforms) {
        confess [1009, 'You already have the maximum number of platforms allowed at this Ministry level.'];
    }
    return 1;
}

sub add_platform {
    my ($self, $asteroid) = @_;
    my $asteroid_ids = $self->asteroid_ids;
    push @{$asteroid_ids}, $asteroid->id;
    $self->asteroid_ids($asteroid_ids);
    $self->recalc_ore_production;
    return $self;
}

sub remove_platform {
    my ($self, $asteroid) = @_;
    my $asteroid_ids = $self->asteroid_ids;
    for (my $i = 0; $i < scalar(@{$asteroid_ids}); $i++) {
        if ($asteroid_ids->[$i] eq $asteroid->id) {
            splice(@{$asteroid_ids}, $i, 1); 
            last;
        }   
    }   
    $self->asteroid_ids($asteroid_ids);
    $self->send_ships_home($asteroid, $self->ship_count - $self->max_ships);
    return $self;
}

sub recalc_ore_production {
    my $self = shift;
    
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
    my $platform_count = $self->platforms->count;
    my $platforms = $self->platforms;
    while (my $platform = $platforms->next) {
        foreach my $ore (ORE_TYPES) {
            my $asteroid = $platform->asteroid;
        }
    }
    
    
    my %asteroids;
    my %production;
    my $ships_per_platform          = $self->ship_count / $self->platform_count;
    my $cargo_space_per_platform    = $ships_per_platform * $self->cargo_ship_hold_size;
    my $cargo_capacity;
    my $cargo_hauled;
    my $production_capacity;
    foreach my $id (@{$self->asteroid_ids}) {
        unless (exists $asteroids{$id}) {
            my $asteroid                    = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body::Asteroid')->find($id);
            my $round_trip_time             =  $self->calculate_seconds_from_body_to_body('cargo_ship', $asteroid, $self->body) * 2;
            my $trips_per_hour              = (3600 / $round_trip_time );
            my $max_cargo_hauled_per_hour   = $trips_per_hour * $cargo_space_per_platform;
            my $cargo_hauled_per_hour       = ($self->platform_production_hour > $max_cargo_hauled_per_hour) ? $max_cargo_hauled_per_hour : $self->platform_production_hour;
            $asteroids{$id} = {
                object                      => $asteroid,
                cargo_hauled_per_hour       => $cargo_hauled_per_hour,
                max_cargo_hauled_per_hour   => $max_cargo_hauled_per_hour,
                };
        }
        $cargo_capacity += $asteroids{$id}{max_cargo_hauled_per_hour};
        $cargo_hauled += $asteroids{$id}{cargo_hauled_per_hour};
        $production_capacity += $self->platform_production_hour;
        foreach my $type (ORE_TYPES) {
            my $hour_method = $type.'_hour';
            $production{$hour_method} += sprintf('%.0f', $asteroids{$id}{object}->$type * $asteroids{$id}{cargo_hauled_per_hour} / 10_000); 
        }
    }
    $production{percent_ship_capacity} = sprintf('%.0f', $cargo_hauled / $cargo_capacity * 100);
    $production{percent_platform_capacity} = sprintf('%.0f', $cargo_hauled / $production_capacity * 100);
    $self->update(\%production);
    $self->body->needs_recalc(1);
    $self->body->update;
    return $self;
}

use constant controller_class => 'Lacuna::Building::MiningMinistry';

use constant university_prereq => 8;

use constant max_instances_per_planet => 1;

use constant image => 'miningministry';

use constant name => 'Mining Ministry';

use constant food_to_build => 137;

use constant energy_to_build => 139;

use constant ore_to_build => 137;

use constant water_to_build => 137;

use constant waste_to_build => 70;

use constant time_to_build => 300;

use constant food_consumption => 11;

use constant energy_consumption => 56;

use constant ore_consumption => 8;

use constant water_consumption => 13;

use constant waste_production => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
