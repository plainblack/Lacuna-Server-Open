package Lacuna::Tutorial;

use Moose;
use utf8;
no warnings qw(uninitialized);

has empire => (
    is          => 'ro',
    required    => 1,
);

sub finish {
    my ($self, $reply) = @_;
    my $method = $self->empire->tutorial_stage;
    if (my $can = $self->can($method)) { # safely call
        my $out = $can->($self, 1);
        if (ref $out eq 'HASH') { # not finished
            if ($reply) {
                $out->{body_prefix} = "It doesn't look like you've completed my last request yet, complete that first. What I said was:\n\n";
                $self->send($out);
            }
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
    $self->empire->update;
    if (my $can = $self->can($stage)) { # safely call
        my $out = $can->($self);
        return $self->send($out);
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
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        if ($home->name ne $empire->tutorial_scratch) {
            $empire->add_medal('pleased_to_meet_you');
            $home->add_plan('Lacuna::DB::Result::Building::Food::Malcud', 1);
            $self->start('get_food');
            return undef;
        }
    }
    $empire->tutorial_scratch($home->name);
    $empire->update;
    return {
        filename    => 'welcome.txt',
        params      => [$empire->name],
    }
}

sub get_food {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $malcud = $home->get_building_of_class('Lacuna::DB::Result::Building::Food::Malcud');
        if (defined $malcud && $malcud->level >= 1) {
            $home->add_trona(700);
            $home->add_bread(700);
            $home->add_energy(700);
            $home->add_water(700);
            $home->update;
            $self->start('drinking_water');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/get_food.txt',  
    };
}

sub keep_the_lights_on {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $geo = $home->get_building_of_class('Lacuna::DB::Result::Building::Energy::Geo');
        if (defined $geo && $geo->level >= 1) {
            $home->add_trona(700);
            $home->add_bread(700);
            $home->add_energy(700);
            $home->add_water(700);
            $home->update;
            $self->start('mine');
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
        my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::Ore::Mine');
        if (defined $building && $building->level >= 1) {
            $home->add_trona(700);
            $home->add_bread(700);
            $home->add_energy(700);
            $home->add_water(700);
            $home->update;
            $self->start('more_resources');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/mine.txt',  
    };
}

sub more_resources {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        if ($home->water_hour >= 100 && $home->energy_hour >= 100 && $home->ore_hour >= 100 && $home->food_hour >= 100) {
            $home->add_trona(700);
            $home->add_bread(700);
            $home->add_energy(700);
            $home->add_water(700);
            $home->update;
            $self->start('university');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/more_resources.txt',  
    };
}

sub spaceport {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::SpacePort');
        if (defined $building && $building->level >= 1) {
            $home->add_bauxite(700);
            $home->add_apple(700);
            $home->add_water(700);
            $home->add_energy(700);
            $home->update;
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
        my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::Shipyard');
        if (defined $building && $building->level >= 1) {
            $home->add_bauxite(700);
            $home->add_apple(700);
            $home->add_water(700);
            $home->add_energy(700);
            $home->update;
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
        my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::Intelligence');
        if (defined $building && $building->level >= 1) {
            $home->add_plan('Lacuna::DB::Result::Building::Intelligence', 2);
            $building->train_spy;
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
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $counter = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({empire_id => $empire->id, task=>'Counter Espionage'})->count;
        if ($counter >= 2) {
            $home->add_trona(700);
            $home->add_bread(700);
            $home->add_energy(700);
            $home->add_water(700);
            $home->update;
            $self->start('observatory');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/counter_spy.txt',  
    };
}

sub observatory {
    my ($self, $finish) = @_;
    my $home = $self->empire->home_planet;
    if ($finish) {
        my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::Observatory');
        if (defined $building && $building->level >= 1) {
            my $shipyard = $home->get_building_of_class('Lacuna::DB::Result::Building::Shipyard');
            if (defined $shipyard) {
                $shipyard->body($home);
                my $probe = Lacuna->db->resultset('Lacuna::DB::Result::Fleet')->new({body=>$home, type=>'probe', quantity => 1,});
                $shipyard->build_fleet($probe);
                $probe->date_available(DateTime->now->add(seconds=>60));
                $probe->update;
                $shipyard->finish_work->update;
                $self->start('explore');
                return undef;
            }
            else {
                $self->send({
                    filename    => 'tutorial/rebuild_the_shipyard.txt',  
                });
                return undef;
            }
        }
    }
    return {
        filename    => 'tutorial/observatory.txt',  
    };
}

sub explore {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    if ($finish) {
        if ($empire->count_probed_stars > 1) {
            $empire->home_planet->add_plan('Lacuna::DB::Result::Building::Transporter', 1);
            $self->start('the_end');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/explore.txt',  
    };
}

sub the_end {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        $home->add_bauxite(2000);
        $home->add_cheese(2000);
        $home->add_energy(2000);
        $home->add_water(2000);
        $home->update;
        my ($x, $y) = $home->find_free_space;
        my $ssd = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
           x        => $x,
           y        => $y,
           class    => 'Lacuna::DB::Result::Building::SubspaceSupplyDepot',
        });
        $home->build_building($ssd);
        $self->start('turing');
        return undef;
    }
    return {
        filename    => 'tutorial/the_end.txt',  
    };
}

sub turing {
    my ($self, $finish) = @_;
    if ($finish) {
        $self->start('turing');
        return undef;
    }
    return {
        filename    => 'tutorial/turing.txt',  
    };
}

sub drinking_water {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::Water::Purification');
        if (defined $building && $building->level >= 1) {
            $home->add_algae(700);
            $home->add_rutile(700);
            $home->add_energy(700);
            $home->add_water(700);
            $home->update;
            $self->start('keep_the_lights_on');
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
        my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::University');
        if (defined $building && $building->level >= 1) {
            $home->add_trona(1000);
            $home->add_bread(1000);
            $home->add_energy(1000);
            $home->add_water(1000);
            $home->update;
            $home->add_plan('Lacuna::DB::Result::Building::MissionCommand', 1);
            foreach my $filename (qw(soylent-trade-opportunity.mission need-a-probe.mission dung-beeldeban.mission)) {
                Lacuna::DB::Result::Mission->initialize($home->zone, $filename);
            }
            $self->start('mission_command');
            return undef;
        }
    }
    return {
        params      => [$empire->name],
        filename    => 'tutorial/university.txt',  
    };
}

sub mission_command {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::MissionCommand');
        if (defined $building && $building->level >= 1) {
            $home->add_trona(700);
            $home->add_bread(700);
            $home->add_energy(700);
            $home->add_water(700);
            $home->update;
            $self->start('storage');
            return undef;
        }
    }
    return {
        params      => [$empire->name],
        filename    => 'tutorial/mission_command.txt',  
    };
}

sub storage {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::Ore::Storage');
        if (defined $building && $building->level >= 1) {
            my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::Water::Storage');
            if (defined $building && $building->level >= 1) {
                my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::Energy::Reserve');
                if (defined $building && $building->level >= 1) {
                    my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::Food::Reserve');
                    if (defined $building && $building->level >= 1) {
                        $home->add_algae(700);
                        $home->add_rutile(700);
                        $home->add_energy(700);
                        $home->add_water(700);
                        $home->update;
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

sub news {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $building = $home->get_building_of_class('Lacuna::DB::Result::Building::Network19');
        if (defined $building && $building->level >= 1) {
            $home->add_algae(700);
            $home->add_rutile(700);
            $home->add_energy(700);
            $home->add_water(700);
            $home->update;
            $self->start('rogue');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/news.txt',  
    };
}

sub rogue {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        if ($empire->description ne '') {
            $home->add_algae(1700);
            $home->add_rutile(1700);
            $home->add_energy(1700);
            $home->add_water(1700);
            $home->update;
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
            $home->add_plan('Lacuna::DB::Result::Building::Food::Reserve', 2);
            $empire->add_essentia({
                amount  => 35, 
                type    => 'free',
                reason  => 'tutorial',
            });
            $empire->update;
            $self->start('essentia');
            return undef;
        }
    }
    my $food_hour = $empire->tutorial_scratch;
    if ($food_hour eq '') {
        $food_hour = $empire->tutorial_scratch($home->food_hour + 20);
        $empire->update;
    }
    return {
        params      => [$food_hour,$food_hour],
        filename    => 'tutorial/fool.txt',  
    };
}

sub essentia {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        my $now = time;
        if ($empire->food_boost->epoch >= $now && $empire->water_boost->epoch >= $now && $empire->ore_boost->epoch >= $now && $empire->energy_boost->epoch >= $now) {
            $home->add_trona(700);
            $home->add_bread(700);
            $home->add_energy(700);
            $home->add_water(700);
            $home->update;
            $self->start('energy');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/essentia.txt',  
    };
}

sub energy {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        if ($home->energy_hour >= $empire->tutorial_scratch) {
            $home->add_plan('Lacuna::DB::Result::Building::Energy::Reserve', 2);
            $self->start('the_300');
            return undef;
        }
    }
    my $energy_hour = $empire->tutorial_scratch;
    if ($energy_hour eq '') {
        $energy_hour = $empire->tutorial_scratch($home->energy_hour + 20);
        $empire->update;
    }
    return {
        params      => [$energy_hour,$energy_hour],
        filename    => 'tutorial/energy.txt',  
    };
}

sub the_300 {
    my ($self, $finish) = @_;
    my $empire = $self->empire;
    my $home = $empire->home_planet;
    if ($finish) {
        if ($home->ore_hour >= 50 && $home->water_hour >= 50) {
            $home->add_plan('Lacuna::DB::Result::Building::Ore::Storage', 2);
            $home->add_plan('Lacuna::DB::Result::Building::Water::Storage', 2);
            $self->start('news');
            return undef;
        }
    }
    return {
        filename    => 'tutorial/the_300.txt',  
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;

