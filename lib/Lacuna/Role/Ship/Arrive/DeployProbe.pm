package Lacuna::Role::Ship::Arrive::DeployProbe;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    # deploy probe
    my $empire = $self->body->empire;
    $empire->add_observatory_probe($self->foreign_star_id, $self->body_id);

    # all pow
    $self->delete;
    confess [-1];
};


after can_send_to_target => sub {
    my ($self, $target) = @_;
    my $body = $self->body;
    my $count = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search_observatory({ body_id => $body->id })->count;
    $count += Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ body_id => $body->id, type=>'probe', task=>'Travelling' })->count;
    my $max_probes = 0;
    my ($observatory) = $body->get_buildings_of_class('Lacuna::DB::Result::Building::Observatory');
    if (defined $observatory) {
        $max_probes = $observatory->max_probes;
    }
    confess [ 1009, 'You are already controlling the maximum amount of probes for your Observatory level.'] if ($count >= $max_probes);
};


1;
