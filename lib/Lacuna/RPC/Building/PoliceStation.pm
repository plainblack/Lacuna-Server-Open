package Lacuna::RPC::Building::PoliceStation;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/policestation';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Module::PoliceStation';
}

sub view_foreign_spies {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my @out;
    my $spies = $building->foreign_spies->search(undef,
        {
            rows        => 25,
            page        => $page_number,
            order_by    => 'available_on',
        }
    );
    while (my $spy = $spies->next) {
        my $available_on = $spy->format_available_on;
        push @out, {
            name                => $spy->name,
            level               => $spy->level,
            task                => $spy->task,
            next_mission        => $available_on,
        };
    }
    return {
        status                  => $self->format_status($empire, $building->body),
        spies                   => \@out,
        spy_count               => $spies->pager->total_entries,
    };
}

sub execute_prisoner {
    my ($self, $session_id, $building_id, $prisoner_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $prisoner = $building->prisoners->find($prisoner_id);
    unless (defined $prisoner) {
        confess [1002,'Could not find that prisoner.'];
    }
    unless (!$prisoner->is_available && $prisoner->task eq 'Captured' && $prisoner->on_body_id == $building->body_id) {
        confess [1010,'That person is not a prisoner.'];
    }
    my $body = $building->body;
    $body->add_news(60, '%s was executed on %s today. Citizens were outraged at the lack of compassion.', $prisoner->name, $body->name);
    $prisoner->empire->send_predefined_message(
        from        => $empire,
        tags        => ['Spies','Alert'],
        filename    => 'spy_executed.txt',
        params      => [$prisoner->name, $prisoner->from_body->id, $prisoner->from_body->name, $body->x, $body->y, $body->name, $empire->id, $empire->name],
    );
    $prisoner->delete;
    return {
        status                  => $self->format_status($empire, $body),
    }
}

sub release_prisoner {
    my ($self, $session_id, $building_id, $prisoner_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $prisoner = $building->prisoners->find($prisoner_id);
    unless (defined $prisoner) {
        confess [1002,'Could not find that prisoner.'];
    }
    unless (!$prisoner->is_available && $prisoner->task eq 'Captured' && $prisoner->on_body_id == $building->body_id) {
        confess [1010,'That person is not a prisoner.'];
    }
    my $body = $building->body;
    $prisoner->task('Idle');
    $prisoner->available_on(DateTime->now);
    $prisoner->update;
    $prisoner->empire->send_predefined_message(
        tags        => ['Spies','Alert'],
        filename    => 'spy_released.txt',
        params      => [$empire->id, $empire->name, $body->x, $body->y, $body->name, $prisoner->name, $prisoner->from_body->id, $prisoner->from_body->name],
    );
    return {
        status                  => $self->format_status($empire, $body),
    }
}

sub view_prisoners {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my @out;
    my $spies = $building->prisoners->search(undef,
        {
            rows        => 25,
            page        => $page_number,
            order_by    => 'available_on',
        }
    );
    while (my $spy = $spies->next) {
        my $available_on = $spy->format_available_on;
        push @out, {
            id                  => $spy->id,
            name                => $spy->name,
            level               => $spy->level,
            task                => $spy->task,
            sentence_expires    => $available_on,
        };
    }
    return {
        status                  => $self->format_status($empire, $building->body),
        prisoners               => \@out,
        captured_count          => $spies->pager->total_entries,
    };
}

sub view_ships_travelling {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my $body = $building->body;
    my @travelling;
    my $ships = $body->ships_travelling->search(undef, {rows=>25, page=>$page_number});
    while (my $ship = $ships->next) {
        $ship->body($body);
        push @travelling, $ship->get_status;
    }
    return {
        status                      => $self->format_status($empire, $body),
        number_of_ships_travelling  => $ships->pager->total_entries,
        ships_travelling            => \@travelling,
    };
}

sub view_foreign_ships {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my @fleet;
    my $now = time;
    my $ships = $building->foreign_ships->search({}, {rows=>25, page=>$page_number, join => 'body' });
    my $see_ship_type = ($building->effective_level * 350) * ( $building->effective_efficiency / 100 );
    my $see_ship_path = ($building->effective_level * 450) * ( $building->effective_efficiency / 100 );
    my @my_planets = $empire->planets->get_column('id')->all;
    while (my $ship = $ships->next) {
        if ($ship->date_available->epoch <= $now) {
            $ship->body->tick;
        }
        else {
            my %ship_info = (
                    id              => $ship->id,
                    name            => 'Unknown',
                    type_human      => 'Unknown',
                    type            => 'unknown',
                    date_arrives    => $ship->date_available_formatted,
                    from            => {},
                );
            if ($ship->body_id ~~ \@my_planets || $see_ship_path >= $ship->stealth) {
                $ship_info{from} = {
                    id      => $ship->body->id,
                    name    => $ship->body->name,
                    empire  => {
                        id      => $ship->body->empire->id,
                        name    => $ship->body->empire->name,
                    },
                };
                if ($ship->body_id ~~ \@my_planets || $see_ship_type >= $ship->stealth) {
                    $ship_info{name} = $ship->name;
                    $ship_info{type} = $ship->type;
                    $ship_info{type_human} = $ship->type_formatted;
                }
            }
            push @fleet, \%ship_info;
        }
    }
    return {
        status                      => $self->format_status($empire, $building->body),
        number_of_ships             => $ships->pager->total_entries,
        ships                       => \@fleet,
    };
}

sub view_ships_orbiting {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my @fleet;
    my $now = time;
    my $ships = $building->orbiting_ships->search({}, {rows=>25, page=>$page_number, join => 'body' });
    my $see_ship_type = ($building->effective_level * 350) * ( $building->effective_efficiency / 100 );
    my $see_ship_path = ($building->effective_level * 450) * ( $building->effective_efficiency / 100 );
    my @my_planets = $empire->planets->get_column('id')->all;
    while (my $ship = $ships->next) {
            if ($ship->date_available->epoch <= $now) {
                $ship->body->tick;
            }
            my %ship_info = (
                    id              => $ship->id,
                    name            => 'Unknown',
                    type_human      => 'Unknown',
                    type            => 'unknown',
                    date_arrived    => $ship->date_available_formatted,
                    from            => {},
                );
            if ($ship->body_id ~~ \@my_planets || $see_ship_path >= $ship->stealth) {
                $ship_info{from} = {
                    id      => $ship->body->id,
                    name    => $ship->body->name,
                    empire  => {
                        id      => $ship->body->empire->id,
                        name    => $ship->body->empire->name,
                    },
                };
                if ($ship->body_id ~~ \@my_planets || $see_ship_type >= $ship->stealth) {
                    $ship_info{name} = $ship->name;
                    $ship_info{type} = $ship->type;
                    $ship_info{type_human} = $ship->type_formatted;
                }
            }
            push @fleet, \%ship_info;
    }
    return {
        status                      => $self->format_status($empire, $building->body),
        number_of_ships             => $ships->pager->total_entries,
        ships                       => \@fleet,
    };
}

__PACKAGE__->register_rpc_method_names(qw(view_prisoners view_foreign_spies execute_prisoner release_prisoner view_ships_travelling view_foreign_ships view_ships_orbiting));

no Moose;
__PACKAGE__->meta->make_immutable;

