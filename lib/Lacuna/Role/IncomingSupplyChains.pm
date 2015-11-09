package Lacuna::Role::IncomingSupplyChains;

use Moose::Role;


sub view_incoming_supply_chains {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    unless ($building) {
        confess [1002, "Cannot find that building."];
    }

    my @supply_chains;
    my $chains      = $building->incoming_supply_chains;
    while (my $chain = $chains->next) {
        push @supply_chains, $chain->get_incoming_status;
    }
    return {
        status          => $self->format_status($empire, $building->body),
        supply_chains  => \@supply_chains,
    };
}

1;
