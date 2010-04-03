package Lacuna::Tutorial;

use Moose;

has empire => (
    is          => 'ro',
    required    => 1,
);

sub finish {
    my ($self) = @_;
    my $method = $self->empire->tutorial_stage;
    if (my $can = $self->can($method)) { # safely call
        my $out = $can->($self, 1);
        if (ref $out eq 'HASH') { # not finished
            $out->{body_prefix} = "It doesn't look like you've completed my last request yet. Complete that first and then email me again. What I said was:\n\n";
            $self->send($out);
            return 0;
        }
        return 1;
    }
    return -1;
}

sub start {
    my ($self, $stage) = @_;
    $self->empire->tutorial_stage($stage);
    $self->empire->tutorial_scratch('');
    $self->empire->put;
    if (my $can = $self->can($stage)) { # safely call
        my $out = $can->($self);
        $self->send($out);
    }
}

sub send {
    my ($self, $options) = @_;
    my $empire = $self->empire;
    $options->{from} = $empire->lacuna_expanse_corp;
    $options->{tags} = ['Tutorial','Correspondence'];
    $empire->send_predefined_message(%{$options});
}

sub explore_the_ui {
    my ($self, $finish) = @_;
    if ($finish) {
        $self->empire->add_medal('pleased_to_meet_you');
        $self->start('get_food');
        return undef;
    }
}

sub get_food {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        if ($home->food_hour >= $empire->tutorial_scratch) {
            $home->add_energy(100);
            $home->put;
            $empire->trigger_full_update;
            $self->start('keep_the_lights_on');
            return undef;
        }
    }
    my $food_hour = $empire->tutorial_scratch;
    if ($food_hour eq '') {
        $food_hour = $empire->tutorial_scratch($home->food_hour + 5);
        $empire->put;
    }
    return {
        params      => [$food_hour, $food_hour],
        filename    => 'tutorial/get_food.txt',  
    };
}

sub keep_the_lights_on {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $geo = $home->get_buildings_of_class('Lacuna::DB::Building::Energy::Geo')->next;
        if (defined $geo && $geo->level >= 1) {
            $home->add_pie(100);
            $home->put;
            $empire->trigger_full_update;
            $self->start('drinking_water');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/keep_the_lights_on.txt',  
    };
}

sub mine {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $building = $home->get_buildings_of_class('Lacuna::DB::Building::Ore::Mine')->next;
        if (defined $building && $building->level >= 1) {
            $home->add_trona(200);
            $home->add_bread(200);
            $home->add_energy(200);
            $home->add_water(200);
            $home->put;
            $empire->trigger_full_update;
            $self->start('university');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/mine.txt',  
    };
}

sub spaceport {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $building = $home->get_buildings_of_class('Lacuna::DB::Building::SpacePort')->next;
        if (defined $building && $building->level >= 1) {
            $home->add_bauxite(300);
            $home->add_apple(500);
            $home->add_water(300);
            $home->put;
            $empire->trigger_full_update;
            $self->start('shipyard');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/spaceport.txt',  
    };
}

sub shipyard {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $building = $home->get_buildings_of_class('Lacuna::DB::Building::Shipyard')->next;
        if (defined $building && $building->level >= 1) {
            $home->add_galena(500);
            $home->put;
            $empire->trigger_full_update;
            $self->start('pawn');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/shipyard.txt',  
    };
}

sub pawn {
    my ($self, $finish) = @_;
    my $home = $self->empire->home_planet;
    if ($finish) {
        my $building = $home->get_buildings_of_class('Lacuna::DB::Building::Intelligence')->next;
        if (defined $building && $building->level >= 1) {
            $home->add_free_upgrade('Lacuna::DB::Building::Intelligence', 2)->put;
            $building->add_counter_spy(1)->put;
            $self->start('counter_spy');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/pawn.txt',  
    };
}

sub counter_spy {
    my ($self, $finish) = @_;
    my $home = $self->empire->home_planet;
    if ($finish) {
        my $building = $home->get_buildings_of_class('Lacuna::DB::Building::Intelligence')->next;
        if (defined $building && $building->count_counter_spies >= 2) {
            $self->start('');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/counter_spy.txt',  
    };
}

sub drinking_water {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $building = $home->get_buildings_of_class('Lacuna::DB::Building::Water::Purification')->next;
        if (defined $building && $building->level >= 1) {
            $home->add_rutile(100);
            $home->put;
            $empire->trigger_full_update;
            $self->start('mine');
            return undef;
        }
    }
    return {
        params      => [sprintf '%.1f', ($home->water/100)],
        filename    => 'tutorial/drinking_water.txt',  
    };
}

sub university {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $building = $home->get_buildings_of_class('Lacuna::DB::Building::University')->next;
        if (defined $building && $building->level >= 1) {
            $home->add_free_build('Lacuna::DB::Building::Ore::Storage', 1)->put;
            $self->start('storage');
            return undef;
        }
    }
    return {
        params      => [$empire->name],
        filename    => 'tutorial/university.txt',  
    };
}

sub storage {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $building = $home->get_buildings_of_class('Lacuna::DB::Building::Ore::Storage')->next;
        if (defined $building && $building->level >= 1) {
            my $building = $home->get_buildings_of_class('Lacuna::DB::Building::Water::Storage')->next;
            if (defined $building && $building->level >= 1) {
                my $building = $home->get_buildings_of_class('Lacuna::DB::Building::Energy::Reserve')->next;
                if (defined $building && $building->level >= 1) {
                    my $building = $home->get_buildings_of_class('Lacuna::DB::Building::Food::Reserve')->next;
                    if (defined $building && $building->level >= 1) {
                        $self->start('fool');
                        return undef;
                    }
                }
            }
        }
    }
    return {
        filename    => 'tutorial/storage.txt',  
    };
}

sub rogue {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    if ($finish) {
        if ($empire->description ne '') {
            $self->start('spaceport');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/rogue.txt',  
    };
}

sub fool {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        if ($home->food_hour >= $empire->tutorial_scratch) {
            $home->add_free_upgrade('Lacuna::DB::Building::Food::Reserve', 2)->put;
            $self->start('energy');
            return undef;
        }
    }
    my $food_hour = $empire->tutorial_scratch;
    if ($food_hour eq '') {
        $food_hour = $empire->tutorial_scratch($home->food_hour + 10);
        $empire->put;
    }
    return {
        params      => [$food_hour],
        filename    => 'tutorial/fool.txt',  
    };
}

sub energy {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        if ($home->energy_hour >= $empire->tutorial_scratch) {
            $home->add_free_upgrade('Lacuna::DB::Building::Energy::Reserve', 2)->put;
            $self->start('the_300');
            return undef;
        }
    }
    my $energy_hour = $empire->tutorial_scratch;
    if ($energy_hour eq '') {
        $energy_hour = $empire->tutorial_scratch($home->energy_hour + 10);
        $empire->put;
    }
    return {
        params      => [$energy_hour],
        filename    => 'tutorial/energy.txt',  
    };
}

sub the_300 {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        if ($home->ore_hour >= 60 && $home->water_hour >= 60) {
            $home->add_free_upgrade('Lacuna::DB::Building::Ore::Storage', 2)
                ->add_free_upgrade('Lacuna::DB::Building::Water::Storage', 2)
                ->put;
            $self->start('rogue');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/the_300.txt',  
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;

