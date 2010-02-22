package Lacuna::Building;

use Moose;
extends 'JSON::RPC::Dispatcher::App';

has simpledb => (
    is      => 'ro',
    required=> 1,
);

with 'Lacuna::Role::Sessionable';

sub model_domain {
    return $_[0]->model_class->domain_name;
}

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

sub has_met_upgrade_prereqs {
    return 1;
}


sub get_building {
    my ($self, $building_id) = @_;
    if (ref $building_id && $building_id->isa('Lacuna::DB::Building')) {
        return $building_id;
    }
    else {
        my $building = $self->simpledb->domain($self->model_domain)->find($building_id);
        if (defined $building) {
            return $building;
        }
        else {
            confess [1002, 'Building does not exist.', $building_id];
        }
    }
}

sub upgrade {
    my ($self, $session_id, $building_id) = @_;
    my $building = $self->get_building($building_id);
    my $empire = $self->get_empire_by_session($session_id);
    unless ($building->empire_id eq $empire->id) {
        confess [1010, "Can't upgrade a building that you don't own.", $building_id];
    }

    # verify upgrade
    my $cost = $building->cost_to_upgrade;
    $building->can_upgrade($cost);

    # spend resources
    my $body = $building->body;
    $body->spend_water($cost->{water});
    $body->spend_energy($cost->{energy});
    $body->spend_food($cost->{food});
    $body->spend_ore($cost->{ore});
    $body->add_waste($cost->{waste});
    $body->put;

    $building->start_upgrade($cost);

    return $self->view($empire, $building);
}

sub view {
    my ($self, $session_id, $building_id) = @_;
    my $building = $self->get_building($building_id);
    my $empire = $self->get_empire_by_session($session_id);
    if ($building->body->empire_id eq $empire->id) { # do body, because permanents aren't owned by anybody
        my $cost = $building->cost_to_upgrade;
        my $queue = $building->build_queue if ($building->build_queue_id);
        my $time_left = 0;
        if (defined $queue) {
            $time_left = $queue->is_complete($building);
        }
        return { 
            building    => {
                id                  => $building->id,
                name                => $building->name,
                image               => $building->image,
                x                   => $building->x,
                y                   => $building->y,
                level               => $building->level,
                food_hour           => $building->food_hour,
                ore_hour            => $building->ore_hour,
                water_hour          => $building->water_hour,
                waste_hour          => $building->waste_hour,
                energy_hour         => $building->energy_hour,
                happiness_hour      => $building->happiness_hour,
                time_left_on_build  => $time_left,
                upgrade             => {
                    can             => (eval{$building->can_upgrade($cost)} ? 1 : 0),
                    cost            => $cost,
                    production      => $building->stats_after_upgrade,
                },
            },
            status      => $empire->get_full_status,
        };
    }
    else {
        confess [1010, "Can't view a building that you don't own.", $building_id];
    }
}

sub build {
    my ($self, $session_id, $body_id, $x, $y) = @_;
    my $body = $self->simpledb->domain('body')->find($body_id);
    my $empire = $self->get_empire_by_session($session_id);

    # make sure is owner
    unless ($body->empire_id eq $empire->id) {
        confess [1010, "Can't add a building to a planet that you don't occupy.", $body_id];
    }

    # create dummy building
    my $building = $self->model_class->new( simpledb => $self->simpledb)->update({
        x               => $x,
        y               => $y,
        level           => 0,
        body_id         => $body->id,
        empire_id       => $empire->id,
        date_created    => DateTime->now,
        class           => $self->model_class,
    });

    # make sure the planet can handle it
    $body->can_build_building($building);

    # adjust resources
    $body->spend_food($building->food_to_build);
    $body->spend_water($building->water_to_build);
    $body->add_waste($building->waste_to_build);
    $body->spend_ore($building->ore_to_build);
    $body->spend_energy($building->energy_to_build);
    $body->put;

    # build it
    $body->build_building($building);

    # show the user
    return $self->view($empire, $building);
}


__PACKAGE__->register_rpc_method_names(qw(upgrade view build));

no Moose;
__PACKAGE__->meta->make_immutable;

