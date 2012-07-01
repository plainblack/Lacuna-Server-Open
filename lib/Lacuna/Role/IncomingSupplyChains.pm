package Lacuna::Role::IncomingSupplyChains;

use Moose::Role;


sub view_incoming_supply_chains {
    my ($self, $session_id, $building_id) = @_;
    my $empire      = $self->get_empire_by_session($session_id);
    my $building    = $self->get_building($empire, $building_id);
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
