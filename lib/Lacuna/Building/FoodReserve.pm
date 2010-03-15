package Lacuna::Building::FoodReserve;

use Moose;
extends 'Lacuna::Building';
use Lacuna::Constants qw(FOOD_TYPES);

sub app_url {
    return '/foodreserve';
}

sub model_class {
    return 'Lacuna::DB::Building::Food::Reserve';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_domain, $building_id);
    my $out = $orig->($self, $empire, $building);
    my %foods;
    my $body = $building->body;
    foreach my $food (FOOD_TYPES) {
        my $method = $food.'_stored';
        $foods{$food} = $body->$method();
    }
    $out->{food_stored} = \%foods;
    return $out;
};


no Moose;
__PACKAGE__->meta->make_immutable;

