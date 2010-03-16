package Lacuna::Building::SpacePort;

use Moose;
extends 'Lacuna::Building';
use Lacuna::Constants qw(SHIP_TYPES);

sub app_url {
    return '/spaceport';
}

sub model_class {
    return 'Lacuna::DB::Building::SpacePort';
}


around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $out = $orig->($self, $empire, $building);
    return $out unless $building->level > 0;
    $building->check_for_completed_ships($building);
    my %ships;
    foreach my $type (SHIP_TYPES) {
        my $count = $type.'_count';
        $ships{$type} = $building->$count;
    }
    $out->{docked_ships} = \%ships;
    return $out;
};

no Moose;
__PACKAGE__->meta->make_immutable;

