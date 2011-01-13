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
    
    # we don't capture if it is an ally
    return if ($body->empire->alliance_id == $self->body->empire->alliance_id);
    
    # set last attack status
    $body->set_last_attacked_by($self->body->id);

    # we don't capture if they don't have a working security ministry
    my $security = $body->get_building_of_class('Lacuna::DB::Result::Building::Security');
    return unless defined $security && $security->efficiency > 0;
    
    # lets see if we can detect the ship
    my $security_detection = ($security->level * 700) * ( $security->efficiency / 100 );
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
        tags        => ['Alert'],
        filename    => 'ship_captured_with_spies.txt',
        params      => [$self->name, $body->x, $body->y, $body->name],
    );
    $self->delete;
    confess [-1];
};

1;
