package Lacuna::Role::Ship::Arrive::CaptureWithSpies;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;
    # we don't capture when coming in to our own planet
    return if $self->direction eq 'in';
    
    # we don't capture if there are no spies
    return unless (
        (exists $self->payload->{spies} && scalar(@{$self->payload->{spies}}))
        || (exists $self->payload->{fetch_spies} && scalar(@{$self->payload->{fetch_spies}}))
        );
    
    # we don't capture if it is from our empire
    my $body = $self->foreign_body;
    return if ($body->empire_id == $self->body->empire_id);
    
    # do nothing, because it is uninhabited
    return if (!$body->empire_id);

    # we don't capture if it is an ally
    return if ($body->empire->alliance_id && $self->body->empire->alliance_id
        && $body->empire->alliance_id == $self->body->empire->alliance_id);
    
    # set last attack status
    $body->set_last_attacked_by($self->body->id);

    my $building = 'Security';
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        $building = 'Module::PoliceStation';
    }
    my $security = $body->get_building_of_class('Lacuna::DB::Result::Building::'.$building);
    return unless defined $security && $security->efficiency > 0;
    
    # lets see if we can detect the ship
    my $security_detection = ($security->effective_level * 700) * ( $security->effective_efficiency / 100 );
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        $security_detection *= 1.5;
    }
    return unless $security_detection > $self->stealth;
    
    # ship detected, time to go kaboom
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies');
    foreach my $id ((@{$self->payload->{spies}}, @{$self->payload->{fetch_spies}})) {
        next unless $id;
        my $spy = $spies->find($id);
        next unless defined $spy;
        $spy->go_to_jail;
        $spy->update;
    }
    $self->body->empire->send_predefined_message(
        tags        => ['Spies','Alert'],
        filename    => 'ship_captured_with_spies.txt',
        params      => [$self->name, $body->x, $body->y, $body->name],
    );
    $body->empire->send_predefined_message(
        tags        => ['Spies','Alert'],
        filename    => 'we_captured_ship_with_spies.txt',
        params      => [$body->id, $body->name, $self->body->empire->id, $self->body->empire->name],
    );
    $self->delete;
    confess [-1];
};

1;
