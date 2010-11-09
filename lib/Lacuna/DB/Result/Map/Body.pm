package Lacuna::DB::Result::Map::Body;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map';

__PACKAGE__->load_components('DynamicSubclass');
__PACKAGE__->table('body');
__PACKAGE__->add_columns(
    star_id                         => { data_type => 'int', is_nullable => 0 },
    orbit                           => { data_type => 'int', default_value => 0 },
    class                           => { data_type => 'varchar', size => 255, is_nullable => 0 },
    size                            => { data_type => 'int', default_value => 0 },
    usable_as_starter               => { data_type => 'int',  default_value => 0 },
    usable_as_starter_enabled       => { data_type => 'tinyint', default_value => 0 },
    empire_id                       => { data_type => 'int', is_nullable => 1 },
    last_tick                       => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    happiness_hour                  => { data_type => 'int', default_value => 0 },
    happiness                       => { data_type => 'int', default_value => 0 },
    waste_hour                      => { data_type => 'int', default_value => 0 },
    waste_stored                    => { data_type => 'int', default_value => 0 },
    waste_capacity                  => { data_type => 'int', default_value => 0 },
    energy_hour                     => { data_type => 'int', default_value => 0 },
    energy_stored                   => { data_type => 'int', default_value => 0 },
    energy_capacity                 => { data_type => 'int', default_value => 0 },
    water_hour                      => { data_type => 'int', default_value => 0 },
    water_stored                    => { data_type => 'int', default_value => 0 },
    water_capacity                  => { data_type => 'int', default_value => 0 },
    ore_capacity                    => { data_type => 'int', default_value => 0 },
    rutile_stored                   => { data_type => 'int', default_value => 0 },
    chromite_stored                 => { data_type => 'int', default_value => 0 },
    chalcopyrite_stored             => { data_type => 'int', default_value => 0 },
    galena_stored                   => { data_type => 'int', default_value => 0 },
    gold_stored                     => { data_type => 'int', default_value => 0 },
    uraninite_stored                => { data_type => 'int', default_value => 0 },
    bauxite_stored                  => { data_type => 'int', default_value => 0 },
    goethite_stored                 => { data_type => 'int', default_value => 0 },
    halite_stored                   => { data_type => 'int', default_value => 0 },
    gypsum_stored                   => { data_type => 'int', default_value => 0 },
    trona_stored                    => { data_type => 'int', default_value => 0 },
    kerogen_stored                  => { data_type => 'int', default_value => 0 },
    methane_stored                  => { data_type => 'int', default_value => 0 },
    anthracite_stored               => { data_type => 'int', default_value => 0 },
    sulfur_stored                   => { data_type => 'int', default_value => 0 },
    zircon_stored                   => { data_type => 'int', default_value => 0 },
    monazite_stored                 => { data_type => 'int', default_value => 0 },
    fluorite_stored                 => { data_type => 'int', default_value => 0 },
    beryl_stored                    => { data_type => 'int', default_value => 0 },
    magnetite_stored                => { data_type => 'int', default_value => 0 },
    rutile_hour                     => { data_type => 'int', default_value => 0 },
    chromite_hour                   => { data_type => 'int', default_value => 0 },
    chalcopyrite_hour               => { data_type => 'int', default_value => 0 },
    galena_hour                     => { data_type => 'int', default_value => 0 },
    gold_hour                       => { data_type => 'int', default_value => 0 },
    uraninite_hour                  => { data_type => 'int', default_value => 0 },
    bauxite_hour                    => { data_type => 'int', default_value => 0 },
    goethite_hour                   => { data_type => 'int', default_value => 0 },
    halite_hour                     => { data_type => 'int', default_value => 0 },
    gypsum_hour                     => { data_type => 'int', default_value => 0 },
    trona_hour                      => { data_type => 'int', default_value => 0 },
    kerogen_hour                    => { data_type => 'int', default_value => 0 },
    methane_hour                    => { data_type => 'int', default_value => 0 },
    anthracite_hour                 => { data_type => 'int', default_value => 0 },
    sulfur_hour                     => { data_type => 'int', default_value => 0 },
    zircon_hour                     => { data_type => 'int', default_value => 0 },
    monazite_hour                   => { data_type => 'int', default_value => 0 },
    fluorite_hour                   => { data_type => 'int', default_value => 0 },
    beryl_hour                      => { data_type => 'int', default_value => 0 },
    magnetite_hour                  => { data_type => 'int', default_value => 0 },
    ore_hour                        => { data_type => 'int', default_value => 0 },
    food_capacity                   => { data_type => 'int', default_value => 0 },
    food_consumption_hour           => { data_type => 'int', default_value => 0 },
    lapis_production_hour           => { data_type => 'int', default_value => 0 },
    potato_production_hour          => { data_type => 'int', default_value => 0 },
    apple_production_hour           => { data_type => 'int', default_value => 0 },
    root_production_hour            => { data_type => 'int', default_value => 0 },
    corn_production_hour            => { data_type => 'int', default_value => 0 },
    cider_production_hour           => { data_type => 'int', default_value => 0 },
    wheat_production_hour           => { data_type => 'int', default_value => 0 },
    bread_production_hour           => { data_type => 'int', default_value => 0 },
    soup_production_hour            => { data_type => 'int', default_value => 0 },
    chip_production_hour            => { data_type => 'int', default_value => 0 },
    pie_production_hour             => { data_type => 'int', default_value => 0 },
    pancake_production_hour         => { data_type => 'int', default_value => 0 },
    milk_production_hour            => { data_type => 'int', default_value => 0 },
    meal_production_hour            => { data_type => 'int', default_value => 0 },
    algae_production_hour           => { data_type => 'int', default_value => 0 },
    syrup_production_hour           => { data_type => 'int', default_value => 0 },
    fungus_production_hour          => { data_type => 'int', default_value => 0 },
    burger_production_hour          => { data_type => 'int', default_value => 0 },
    shake_production_hour           => { data_type => 'int', default_value => 0 },
    beetle_production_hour          => { data_type => 'int', default_value => 0 },
    bean_production_hour            => { data_type => 'int', default_value => 0 },
    cheese_production_hour          => { data_type => 'int', default_value => 0 },
    cheese_stored                   => { data_type => 'int', default_value => 0 },
    bean_stored                     => { data_type => 'int', default_value => 0 },
    lapis_stored                    => { data_type => 'int', default_value => 0 },
    potato_stored                   => { data_type => 'int', default_value => 0 },
    apple_stored                    => { data_type => 'int', default_value => 0 },
    root_stored                     => { data_type => 'int', default_value => 0 },
    corn_stored                     => { data_type => 'int', default_value => 0 },
    cider_stored                    => { data_type => 'int', default_value => 0 },
    wheat_stored                    => { data_type => 'int', default_value => 0 },
    bread_stored                    => { data_type => 'int', default_value => 0 },
    soup_stored                     => { data_type => 'int', default_value => 0 },
    chip_stored                     => { data_type => 'int', default_value => 0 },
    pie_stored                      => { data_type => 'int', default_value => 0 },
    pancake_stored                  => { data_type => 'int', default_value => 0 },
    milk_stored                     => { data_type => 'int', default_value => 0 },
    meal_stored                     => { data_type => 'int', default_value => 0 },
    algae_stored                    => { data_type => 'int', default_value => 0 },
    syrup_stored                    => { data_type => 'int', default_value => 0 },
    fungus_stored                   => { data_type => 'int', default_value => 0 },
    burger_stored                   => { data_type => 'int', default_value => 0 },
    shake_stored                    => { data_type => 'int', default_value => 0 },
    beetle_stored                   => { data_type => 'int', default_value => 0 },
    boost_enabled                   => { data_type => 'tinyint', default_value => 0 },
    needs_recalc                    => { data_type => 'tinyint', default_value => 0 },
    needs_surface_refresh           => { data_type => 'tinyint', default_value => 0 },
    restrict_coverage               => { data_type => 'tinyint', default_value => 0 },
    plots_available                 => { data_type => 'tinyint', default_value => 0 },    
);

after 'sqlt_deploy_hook' => sub {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_class', fields => ['class']);
    $sqlt_table->add_index(name => 'idx_usable_as_starter', fields => ['usable_as_starter']);
    $sqlt_table->add_index(name => 'idx_usable_as_starter_enabled', fields => ['usable_as_starter_enabled']);
    $sqlt_table->add_index(name => 'idx_planet_search', fields => ['usable_as_starter_enabled','usable_as_starter']);
};

__PACKAGE__->typecast_map(class => {
    'Lacuna::DB::Result::Map::Body::Asteroid::A1' => 'Lacuna::DB::Result::Map::Body::Asteroid::A1',
    'Lacuna::DB::Result::Map::Body::Asteroid::A2' => 'Lacuna::DB::Result::Map::Body::Asteroid::A2',
    'Lacuna::DB::Result::Map::Body::Asteroid::A3' => 'Lacuna::DB::Result::Map::Body::Asteroid::A3',
    'Lacuna::DB::Result::Map::Body::Asteroid::A4' => 'Lacuna::DB::Result::Map::Body::Asteroid::A4',
    'Lacuna::DB::Result::Map::Body::Asteroid::A5' => 'Lacuna::DB::Result::Map::Body::Asteroid::A5',
    'Lacuna::DB::Result::Map::Body::Asteroid::A6' => 'Lacuna::DB::Result::Map::Body::Asteroid::A6',
    'Lacuna::DB::Result::Map::Body::Asteroid::A7' => 'Lacuna::DB::Result::Map::Body::Asteroid::A7',
    'Lacuna::DB::Result::Map::Body::Asteroid::A8' => 'Lacuna::DB::Result::Map::Body::Asteroid::A8',
    'Lacuna::DB::Result::Map::Body::Asteroid::A9' => 'Lacuna::DB::Result::Map::Body::Asteroid::A9',
    'Lacuna::DB::Result::Map::Body::Asteroid::A10' => 'Lacuna::DB::Result::Map::Body::Asteroid::A10',
    'Lacuna::DB::Result::Map::Body::Asteroid::A11' => 'Lacuna::DB::Result::Map::Body::Asteroid::A11',
    'Lacuna::DB::Result::Map::Body::Asteroid::A12' => 'Lacuna::DB::Result::Map::Body::Asteroid::A12',
    'Lacuna::DB::Result::Map::Body::Asteroid::A13' => 'Lacuna::DB::Result::Map::Body::Asteroid::A13',
    'Lacuna::DB::Result::Map::Body::Asteroid::A14' => 'Lacuna::DB::Result::Map::Body::Asteroid::A14',
    'Lacuna::DB::Result::Map::Body::Asteroid::A15' => 'Lacuna::DB::Result::Map::Body::Asteroid::A15',
    'Lacuna::DB::Result::Map::Body::Asteroid::A16' => 'Lacuna::DB::Result::Map::Body::Asteroid::A16',
    'Lacuna::DB::Result::Map::Body::Asteroid::A17' => 'Lacuna::DB::Result::Map::Body::Asteroid::A17',
    'Lacuna::DB::Result::Map::Body::Asteroid::A18' => 'Lacuna::DB::Result::Map::Body::Asteroid::A18',
    'Lacuna::DB::Result::Map::Body::Asteroid::A19' => 'Lacuna::DB::Result::Map::Body::Asteroid::A19',
    'Lacuna::DB::Result::Map::Body::Asteroid::A20' => 'Lacuna::DB::Result::Map::Body::Asteroid::A20',
    'Lacuna::DB::Result::Map::Body::Planet::P1' => 'Lacuna::DB::Result::Map::Body::Planet::P1',
    'Lacuna::DB::Result::Map::Body::Planet::P2' => 'Lacuna::DB::Result::Map::Body::Planet::P2',
    'Lacuna::DB::Result::Map::Body::Planet::P3' => 'Lacuna::DB::Result::Map::Body::Planet::P3',
    'Lacuna::DB::Result::Map::Body::Planet::P4' => 'Lacuna::DB::Result::Map::Body::Planet::P4',
    'Lacuna::DB::Result::Map::Body::Planet::P5' => 'Lacuna::DB::Result::Map::Body::Planet::P5',
    'Lacuna::DB::Result::Map::Body::Planet::P6' => 'Lacuna::DB::Result::Map::Body::Planet::P6',
    'Lacuna::DB::Result::Map::Body::Planet::P7' => 'Lacuna::DB::Result::Map::Body::Planet::P7',
    'Lacuna::DB::Result::Map::Body::Planet::P8' => 'Lacuna::DB::Result::Map::Body::Planet::P8',
    'Lacuna::DB::Result::Map::Body::Planet::P9' => 'Lacuna::DB::Result::Map::Body::Planet::P9',
    'Lacuna::DB::Result::Map::Body::Planet::P10' => 'Lacuna::DB::Result::Map::Body::Planet::P10',
    'Lacuna::DB::Result::Map::Body::Planet::P11' => 'Lacuna::DB::Result::Map::Body::Planet::P11',
    'Lacuna::DB::Result::Map::Body::Planet::P12' => 'Lacuna::DB::Result::Map::Body::Planet::P12',
    'Lacuna::DB::Result::Map::Body::Planet::P13' => 'Lacuna::DB::Result::Map::Body::Planet::P13',
    'Lacuna::DB::Result::Map::Body::Planet::P14' => 'Lacuna::DB::Result::Map::Body::Planet::P14',
    'Lacuna::DB::Result::Map::Body::Planet::P15' => 'Lacuna::DB::Result::Map::Body::Planet::P15',
    'Lacuna::DB::Result::Map::Body::Planet::P16' => 'Lacuna::DB::Result::Map::Body::Planet::P17',
    'Lacuna::DB::Result::Map::Body::Planet::P17' => 'Lacuna::DB::Result::Map::Body::Planet::P17',
    'Lacuna::DB::Result::Map::Body::Planet::P18' => 'Lacuna::DB::Result::Map::Body::Planet::P18',
    'Lacuna::DB::Result::Map::Body::Planet::P19' => 'Lacuna::DB::Result::Map::Body::Planet::P19',
    'Lacuna::DB::Result::Map::Body::Planet::P20' => 'Lacuna::DB::Result::Map::Body::Planet::P20',
    'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G1' => 'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G1',
    'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G2' => 'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G2',
    'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G3' => 'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G3',
    'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G4' => 'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G4',
    'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G5' => 'Lacuna::DB::Result::Map::Body::Planet::GasGiant::G5',
});

# RELATIONSHIPS

__PACKAGE__->belongs_to('star', 'Lacuna::DB::Result::Map::Star', 'star_id');
__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id');
__PACKAGE__->has_many('buildings','Lacuna::DB::Result::Building','body_id');


sub lock {
    my $self = shift;
    return Lacuna->cache->set('planet_contention_lock', $self->id, 1, 15); # lock it
}

sub is_locked {
    my $self = shift;
    return Lacuna->cache->get('planet_contention_lock', $self->id);
}

sub image {
    confess "override me";
}

sub image_name {
    my $self = shift;
    return $self->image.'-'.$self->orbit;
}

sub get_type {
    my ($self) = @_;
    my $type = 'habitable planet';
    if ($self->isa('Lacuna::DB::Result::Map::Body::Planet::GasGiant')) {
        $type = 'gas giant';
    }
    elsif ($self->isa('Lacuna::DB::Result::Map::Body::Asteroid')) {
        $type = 'asteroid';
    }
    elsif ($self->isa('Lacuna::DB::Result::Map::Body::Station')) {
        $type = 'space station';
    }
    return $type;
}

sub get_status {
    my ($self) = @_;
    my %out = (
        name            => $self->name,
        image           => $self->image_name,
        x               => $self->x,
        y               => $self->y,
        orbit           => $self->orbit,
        size            => $self->size,
        type            => $self->get_type,
        star_id         => $self->star_id,
        star_name       => $self->star->name,
        id              => $self->id,
    );
    return \%out;
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
