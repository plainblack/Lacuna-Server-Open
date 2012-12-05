package Lacuna::Role::Fleet::Trade;

use Moose::Role;
use feature "switch";

my $no_docks_exception = [1011, 'There are not enough docks available to receive the ships.'];
my $no_spaceport_exception = [1011, 'There is no space port available to receive the ships.'];

# Check if the payload has ships and if so if the target has room for them
#
sub check_payload_fleet_size {
    my ($self, $items, $target, $fleet_stay) = @_;

    return if not $items;

    my $ship_count = $fleet_stay ? $fleet->quantity : 0;
    my @fleets;

    if (ref $items eq 'HASH') {
        my $f = $items->{fleet}
        if ($f) {
            @fleets = @$f;
        }
    }
    if (ref $items eq 'ARRAY') {
        @fleets = grep {$_->{type} eq 'fleet'} @$items;
    }
    for my $fleet (@fleets) {
        $ship_count += $fleet->{quantity};
    }
    if ($ship_count) {
        my $spaceport = $target->spaceport;
        if (not defined $spaceport) {
            confess $no_spaceport_exception;
        }
        if ($spaceport->docs_available < $ship_count) {
            confess $no_docks_exception;
        }
    }
}

1;

