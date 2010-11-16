package Lacuna::RPC::Building::FoodReserve;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Constants qw(FOOD_TYPES);

sub app_url {
    return '/foodreserve';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Reserve';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
    my %foods;
    my $body = $building->body;
    foreach my $food (FOOD_TYPES) {
        $foods{$food} = $body->type_stored($food);
    }
    $out->{food_stored} = \%foods;
    return $out;
};

sub dump {
    my ($self, $session_id, $building_id, $type, $amount) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;
    $body->spend_type($type, $amount);
    $body->add_type('waste', $amount);
    $body->update;
    return {
        status      => $self->format_status($empire, $body),
        };
}

__PACKAGE__->register_rpc_method_names(qw(dump));


no Moose;
__PACKAGE__->meta->make_immutable;

