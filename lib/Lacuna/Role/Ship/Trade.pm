package Lacuna::Role::Ship::Trade;

use Moose::Role;
use feature "switch";

my $no_docks_exception = [1011, 'There are not enough docks available to receive the ships.'];
my $no_spaceport_exception = [1011, 'There is no space port available to receive the ships.'];

# Check if the payload has ships, in which case ensure the target can accept them
#
sub check_payload_ships {
    my ($self, $items, $target, $ship_stay) = @_;

    my $ship_count = grep {$_->{type} eq 'ship'} @$items;

    $ship_count++ if $ship_stay;

    my $spaceport = $target->spaceport;
    if ($ship_count) {
        my $spaceport = $target->spaceport;
        if (not defined $spaceport) {
            confess $no_spaceport_exception;
        }
        if ($spaceport->docks_available < $ship_count) {
            confess $no_docks_exception;
        }
    }
}

1;

