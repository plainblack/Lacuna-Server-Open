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
        }
    }
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
        $self->start('get_food');
        $self->empire->add_medal('pleased_to_meet_you');
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
            $self->start('keep_the_lights_on');
            return undef;
        }
    }
    my $food_hour = $empire->tutorial_scratch;
    if ($food_hour eq '') {
        $food_hour = $empire->tutorial_scratch($home->food_hour + 50);
        $empire->put;
    }
    return {
        params      => [$food_hour, $food_hour],
        filename    => 'tutorial/get_food.txt',  
    };
}

sub keep_the_lights_on {
    my ($self, $finish) = @_;
    my $home = $self->empire->home_planet;
    if ($finish) {
        my $geo = $home->get_buildings_of_class('Lacuna::DB::Building::Energy::Geo')->next;
        if (defined $geo && $geo->level >= 1) {
            $home->add_pie(100);
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
    my $home = $self->empire->home_planet;
    if ($finish) {
        my $building = $home->get_buildings_of_class('Lacuna::DB::Building::Ore::Mine')->next;
        if (defined $building && $building->level >= 1) {
            $home->add_trona(200);
            $home->add_bread(200);
            $home->add_energy(200);
            $home->add_water(200);
            $self->start('university');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/mine.txt',  
    };
}

sub drinking_water {
    my ($self, $finish) = @_;
    my $home = $self->empire->home_planet;
    if ($finish) {
        my $building = $home->get_buildings_of_class('Lacuna::DB::Building::Water::Purification')->next;
        if (defined $building && $building->level >= 1) {
            $home->add_rutile(100);
            $self->start('mine');
            return undef;
        }
    }
    return {
        params      => [sprintf '%.1f', $home->water],
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
            $empire->add_free_build('Lacuna::DB::Building::Ore::Storage', 1)->put;
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
                        $empire->add_medal('hoarder');
                        $self->start('');
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

no Moose;
__PACKAGE__->meta->make_immutable;

