package Lacuna::Role::Fleet::Arrive::AddGasGiantPlatform;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    # Add one plan for each ship in the fleet
    my $lab = $self->body->get_building_of_class('Lacuna::DB::Result::Building::GasGiantLab');
    $self->foreign_body->add_plan('Lacuna::DB::Result::Building::Permanent::GasGiantPlatform', 1, (defined $lab) ? $lab->level : 0, $self->quantity);
    
    $self->delete;
    confess [-1];
};


1;
