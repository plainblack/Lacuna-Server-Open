package Lacuna::RPC::Building;

use Moose;
use utf8;
use Data::Dumper;

no warnings qw(uninitialized);
extends 'Lacuna::RPC';

sub model_class {
    confess "you need to override me";
}

sub app_url {
    confess "you need to override me";
}

sub to_app_with_url {
    my $self = shift;
    return ($self->app_url => $self->to_app);
}

sub upgrade {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            building_id => shift,
        };
    }

    my $session     = $self->get_session($args);
    my $empire      = $session->current_empire;
    my $building    = $session->current_building;

    # check the upgrade lock
    if ($building->is_upgrade_locked) {
        confess [1013, "An upgrade request is already being processed on this building."];
    }
    else {
        $building->lock_upgrade;
    }

    # verify upgrade
    my $cost = $building->cost_to_upgrade;
    $building->can_upgrade($cost);

    # spend resources
    my $body = $building->body;
    my $plan = $body->get_plan($building->class, $building->level + 1);
    if (defined $plan) {
        $body->delete_one_plan($plan);
        $cost->{halls} = 0;
    }
    else {
        $body->spend_water($cost->{water});
        $body->spend_energy($cost->{energy});
        $body->spend_food($cost->{food}, 0);
        $body->spend_ore($cost->{ore});
        $body->add_waste($cost->{waste});
        $body->update;
        $cost->{halls} = $building->level + 1;
    }

    $building->start_upgrade($cost);
    
    # add vote
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        my $name = $building->name.' ('.$building->x.','.$building->y.')';
        my $proposition = Lacuna->db->resultset('Propositions')->new({
            type            => 'UpgradeModule',
            name            => 'Upgrade '.$name,
            description     => 'Upgrade '.$name.' on {Planet '.$body->id.' '.$body->name.'} from level '.$building->level.' to '.($building->level + 1).'.',
            scratch         => { building_id => $building->id, to_level => $building->level + 1 },
            proposed_by_id  => $empire->id,
        });
        $proposition->station($body);
        $proposition->proposed_by($empire);
        $proposition->insert;
    }
    
    return {
        status      => $self->format_status($session, $body),
        building    => {
            id              => 0+$building->id,
            level           => 0+$building->level,
            pending_build   => $building->upgrade_status,
        },
    };
}

sub view {
    my $self = shift;
    my $args = shift;
        
    if (ref($args) ne "HASH") {
        $args = {
            session_id   => $args,
            building_id  => shift,
        };
    }
    if ($args->{no_status}) {
        return {};
    }

    my $session         = $self->get_session($args);
    my $empire          = $session->current_empire;
    my $building        = $session->current_building;
    my $cost            = $building->cost_to_upgrade;

    my $can_upgrade     = eval{$building->can_upgrade($cost)};
    my $upgrade_reason  = $@;

    my $can_downgrade   = eval{$building->can_downgrade};
    my $downgrade_reason = $@;

    my $image_after_upgrade = $building->image_level($building->level + 1);
    my $image_after_downgrade = $building->image_level($building->level > 0 ? $building->level - 1 : 0);

    my $status = $self->format_status($session);

    my %out = ( 
        building    => {
            id                  => 0+$building->id,
            name                => $building->name,
            image               => $building->image_level,
            x                   => 0+$building->x,
            y                   => 0+$building->y,
            level               => 0+$building->level,
            food_hour           => 0+$building->food_hour,
            food_capacity       => 0+$building->food_capacity,
            ore_hour            => 0+$building->ore_hour,
            ore_capacity        => 0+$building->ore_capacity,
            water_hour          => 0+$building->water_hour,
            water_capacity      => 0+$building->water_capacity,
            waste_hour          => 0+$building->waste_hour,
            waste_capacity      => 0+$building->waste_capacity,
            energy_hour         => 0+$building->energy_hour,
            energy_capacity     => 0+$building->energy_capacity,
            happiness_hour      => 0+$building->happiness_hour,
            efficiency          => 0+$building->efficiency,
            repair_costs        => $building->get_repair_costs,
            body_id             => $building->body_id,
            upgrade             => {
                can             => ($can_upgrade ? 1 : 0),
                reason          => $upgrade_reason,
                cost            => $cost,
                production      => $building->stats_after_upgrade,
                image           => $image_after_upgrade,
            },
            downgrade           => {
                can             => ($can_downgrade ? 1 : 0),
                reason          => $downgrade_reason,
                image           => $image_after_downgrade,
            },
            pending_build       => $building->upgrade_status,
        },
        status      => $status,
    );
    if ($building->is_working) {
        $out{building}{work} = {
            seconds_remaining   => 0+$building->work_seconds_remaining,
            start               => $building->work_started_formatted,
            end                 => $building->work_ends_formatted,
        };
    }

    return \%out;
}

sub build {
    my $self = shift;
    my $args = shift;
        
    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            body_id         => shift,
            x               => shift,
            y               => shift,
        };
    }

    my $session = $self->get_session({session_id => $args->{session_id}, body_id => $args->{body_id}});
    my $empire  = $session->current_empire;
    my $body    = $session->current_body;
    my $x       = $args->{x};
    my $y       = $args->{y};

    if ($x eq '' || $y eq '' || $x < -5 || $y < -5 || $x > 5 || $y > 5) {
        confess [1009, "You must specify an x,y coordinate to place the building that is between -5 and 5.", [$x, $y]];
    }

    # check the plot lock
    if ($body->is_plot_locked($x, $y)) {
        confess [1013, "That plot is reserved for another building.", [$x,$y]];
    }
    else {
        $body->lock_plot($x,$y);
    }

    # create dummy building
    my $building = Lacuna->db->resultset('Building')->new({
        x               => $x,
        y               => $y,
        level           => 0,
        body_id         => $body->id,
        body            => $body,
        class           => $self->model_class,
    });

    # make sure the planet can handle it
    my $cost = $building->cost_to_upgrade;
    $body = $body->can_build_building($building);

    # adjust resources
    my $plan = $body->get_plan($building->class, 1);
    if (defined $plan) {
        if ($plan->extra_build_level) {
            $building->level($plan->extra_build_level);
            $body->needs_recalc(1);
            $body->update;
        }
        $body->delete_one_plan($plan);
    }
    else {
        $body->spend_food($cost->{food}, 0);
        $body->spend_water($cost->{water});
        $body->add_waste($cost->{waste});
        $body->spend_ore($cost->{ore});
        $body->spend_energy($cost->{energy});
        $body->update;
    }

    # build it
    $body->build_building($building);
    
    # add vote
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        my $name = $building->name.' ('.$building->x.','.$building->y.')';
        my $proposition = Lacuna->db->resultset('Propositions')->new({
            type            => 'InstallModule',
            name            => 'Install '.$name,
            description     => 'Install '.$name.' on {Planet '.$body->id.' '.$body->name.'}.',
            scratch         => { building_id => $building->id, to_level => $building->level + 1 },
            proposed_by_id  => $empire->id,
        });
        $proposition->station($body);
        $proposition->proposed_by($empire);
        $proposition->insert;
    }
    
    # show the user
    my %out = (
        status      => $self->format_status($session, $body),
        building    => {
            id              => 0+$building->id,
            level           => 0+$building->level,
            pending_build   => $building->upgrade_status,
        },
    );
    if ($building->is_working) {
        $out{building}{work} = {
            seconds_remaining   => 0+$building->work_seconds_remaining,
            start               => $building->work_started_formatted,
            end                 => $building->work_ends_formatted,
        };
    }

    return \%out;
}

sub demolish {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            building_id => shift,
        };
    }
                                                                                            
    my $session = $self->get_session({session_id => $args->{building_id}, body_id => $args->{building_id}});
    my $empire      = $session->current_empire;
    my $building    = $self->get_building($empire, $args->{building_id});

    my $body = $building->body;
    $building->can_demolish;
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        unless ($body->parliament && $body->parliament->effective_level >= 2) {
            confess [1013, 'You need to have a level 2 Parliament to demolish a module.'];
        }
        if ($building->class =~ /^Lacuna::DB::Result::Building::Module::/) {
            my $name = $building->name.' ('.$building->x.','.$building->y.')';
            my $proposition = Lacuna->db->resultset('Propositions')->new({
                type            => 'DemolishModule',
                name            => 'Demolish '.$name,
                description     => 'Demolish '.$name.' on {Planet '.$body->id.' '.$body->name.'}.',
                scratch         => { building_id => $building->id },
                proposed_by_id  => $empire->id,
            });
            $proposition->station($body);
            $proposition->proposed_by($empire);
            $proposition->insert;
            confess [1017, 'The demolish order has been delayed pending a parliamentary vote.'];
        }
    }
    $building->demolish;
    $body->tick;
    return {
        status      => $self->format_status($session, $body),
    };
}

sub downgrade {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            building_id => shift,
        };
    }
                                                                                            
    my $session     = $self->get_session($args);
    my $empire      = $session->current_empire;
    my $building    = $session->current_building;

    my $body = $building->body;

    $building->can_downgrade;
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        unless ($body->parliament && $body->parliament->effective_level >= 2) {
            confess [1013, 'You need to have a level 2 Parliament to downgrade a module.'];
        }
        if ($building->class =~ /^Lacuna::DB::Result::Building::Module::/) {
            my $name = $building->name.' ('.$building->x.','.$building->y.')';
            my $proposition = Lacuna->db->resultset('Propositions')->new({
                type            => 'DowngradeModule',
                name            => 'Downgrade '.$name,
                description     => 'Downgrade '.$name.' on {Planet '.$body->id.' '.$body->name.'} from level '.$building->level.' to '.($building->level - 1).'.',
                scratch         => { building_id => $building->id },
                proposed_by_id  => $empire->id,
            });
            $proposition->station($body);
            $proposition->proposed_by($empire);
            $proposition->insert;
            confess [1017, 'The downgrade order has been delayed pending a parliamentary vote.'];
        }
    }
    $building->downgrade;
    $body->tick;
    return $self->view($empire, $building);
}

sub get_stats_for_level {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            building_id => shift,
            level       => shift,
        };
    }
                                                                                            
    my $session     = $self->get_session($args);
    my $empire      = $session->current_empire;
    my $building    = $session->current_building;
    my $level       = $args->{level};
    
    if ($level < 0 || $level > 100) {
        confess [1009, 'Level must be an integer between 1 and 100.'];
    }
    $building->level($level);
    $building->clear_effective_level;
    my $image_after_upgrade = $building->image_level($building->level + 1);
    return {
        building    => {
            id                  => 0+$building->id,
            name                => $building->name,
            image               => $building->image_level,
            level               => 0+$building->level,
            food_hour           => 0+$building->food_hour,
            food_capacity       => 0+$building->food_capacity,
            ore_hour            => 0+$building->ore_hour,
            ore_capacity        => 0+$building->ore_capacity,
            water_hour          => 0+$building->water_hour,
            water_capacity      => 0+$building->water_capacity,
            waste_hour          => 0+$building->waste_hour,
            waste_capacity      => 0+$building->waste_capacity,
            energy_hour         => 0+$building->energy_hour,
            energy_capacity     => 0+$building->energy_capacity,
            happiness_hour      => 0+$building->happiness_hour,
            upgrade             => {
                cost            => $building->cost_to_upgrade,
                production      => $building->stats_after_upgrade,
                image           => $image_after_upgrade,
            },
        },
        status      => $self->format_status($session, $building->body),
    };
}

sub repair {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            building_id => shift,
        };
    }
                                                                                            
    my $session     = $self->get_session($args);
    my $empire      = $session->current_empire;
    my $building    = $session->current_building;

    my $costs = $building->get_repair_costs;
    $building->can_repair($costs);
    my $body = $building->body;
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        my $name = $building->name.' ('.$building->x.','.$building->y.')';
        my $proposition = Lacuna->db->resultset('Propositions')->new({
            type            => 'RepairModule',
            name            => 'Repair '.$name,
            description     => 'Repair '.$name.' on {Planet '.$body->id.' '.$body->name.'}.',
            scratch         => { building_id => $building->id },
            proposed_by_id  => $empire->id,
        });
        $proposition->station($body);
        $proposition->proposed_by($empire);
        $proposition->insert;
        confess [1017, 'The repair order has been delayed pending a parliamentary vote.'];
    }
    $building->repair($costs);
    return $self->view($empire, $building);
}

__PACKAGE__->register_rpc_method_names(qw(
    repair 
    downgrade 
    get_repair_costs 
    demolish 
    upgrade 
    view 
    build 
    get_stats_for_level
));

no Moose;
__PACKAGE__->meta->make_immutable;

