package Lacuna::RPC::Building::MiningMinistry;

use Moose;
use utf8;
use Lacuna::Constants qw(SHIP_TRADE_TYPES);
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/miningministry';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Ore::Ministry';
}

sub view_ships {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ 
        body_id => $building->body_id, 
        task    => { in => ['Mining', 'Docked']},
        type    => { in => [SHIP_TRADE_TYPES] },
    });
    my @fleet;
    while (my $ship = $ships->next) {
        push @fleet, {
            id          => $ship->id,
            name        => $ship->name,
            speed       => $ship->speed,
            hold_size   => $ship->hold_size,
            berth_level => $ship->berth_level,
            task        => $ship->task,
        };
    }
    return {
        ships           => \@fleet,
        status          => $self->format_status($empire, $building->body),
    };
}

sub view_platforms {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $platforms = $building->platforms;
    my @fleet;
    while (my $platform = $platforms->next) {
        push @fleet, {
            id                              => $platform->id,
            asteroid                        => $platform->asteroid->get_status,
            rutile_hour                     => $platform->rutile_hour,
            chromite_hour                   => $platform->chromite_hour,
            chalcopyrite_hour               => $platform->chalcopyrite_hour,
            galena_hour                     => $platform->galena_hour,
            gold_hour                       => $platform->gold_hour,
            uraninite_hour                  => $platform->uraninite_hour,
            bauxite_hour                    => $platform->bauxite_hour,
            goethite_hour                   => $platform->goethite_hour,
            halite_hour                     => $platform->halite_hour,
            gypsum_hour                     => $platform->gypsum_hour,
            trona_hour                      => $platform->trona_hour,
            kerogen_hour                    => $platform->kerogen_hour,
            methane_hour                    => $platform->methane_hour,
            anthracite_hour                 => $platform->anthracite_hour,
            sulfur_hour                     => $platform->sulfur_hour,
            zircon_hour                     => $platform->zircon_hour,
            monazite_hour                   => $platform->monazite_hour,
            fluorite_hour                   => $platform->fluorite_hour,
            beryl_hour                      => $platform->beryl_hour,
            magnetite_hour                  => $platform->magnetite_hour,  
            shipping_capacity               => $platform->percent_ship_capacity,
        };
    }
    return {
        platforms       => \@fleet,
        max_platforms   => $building->max_platforms,
        status          => $self->format_status($empire, $building->body),
    };
}

sub abandon_platform {
    my ($self, $session_id, $building_id, $platform_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $platform = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->find($platform_id);
    unless (defined $platform) {
        confess [1002, "Platform not found."];
    }
    unless ($platform->planet_id eq $building->body_id) {
        confess [1013, "You can't abandon a platform that is not yours."];
    }
    $building->remove_platform($platform);
    return {
        status  => $self->format_status($empire, $building->body),
    };
}

sub mass_abandon_platform {
    my ($self, $session_id, $building_id, $ship_ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
	$building->platforms->delete;
	return {
        status  => $self->format_status($empire, $building->body),
    }; 
}

sub add_cargo_ship_to_fleet {
    my ($self, $session_id, $building_id, $ship_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, "Ship not found."];
    }
    unless ($ship->task eq 'Docked') {
        confess [1009, "That ship is not available."];
    }
    unless ($ship->hold_size > 0) {
        confess [1009, 'That ship has no cargo hold.'];
    }
    unless ($ship->body_id eq $building->body_id) {
        confess [1013, "You can't manage a ship that is not yours."];
    }
    unless ($building->body->max_berth >= $ship->berth_level) {
        confess [1009, 'Max Berth Level is '.$building->body->max_berth.' for ships on this planet.' ];
    }
    $building->add_ship($ship);
    return {
        status  =>$self->format_status($empire, $building->body),
    };
}

sub remove_cargo_ship_from_fleet {
    my ($self, $session_id, $building_id, $ship_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    unless (defined $ship) {
        confess [1002, "Ship not found."];
    }
    unless ($ship->task eq 'Mining') {
        confess [1009, "That ship is not mining."];
    }
    unless ($ship->body_id eq $building->body_id) {
        confess [1013, "You can't manage a ship that is not yours."];
    }
    my $platform = $building->platforms->search(undef, {rows => 1})->single;
    if (defined $platform) {
        my $from = $platform->asteroid;
        unless (defined $from) {
            $from = $building->body;
        }
        $building->send_ship_home($from, $ship);
    }
    else {
        $ship->land->update;
    }
    return {
        status  => $self->format_status($empire, $building->body),
    };
}


__PACKAGE__->register_rpc_method_names(qw(view_platforms view_ships abandon_platform remove_cargo_ship_from_fleet add_cargo_ship_to_fleet));

no Moose;
__PACKAGE__->meta->make_immutable;

