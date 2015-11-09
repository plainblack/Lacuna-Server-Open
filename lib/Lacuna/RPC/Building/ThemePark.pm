package Lacuna::RPC::Building::ThemePark;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/themepark';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::ThemePark';
}


around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id, skip_offline => 1 });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $out = $orig->($self, $session, $building);
    if ($building->is_working) {
        $out->{themepark} = {
            food_type_count           => $building->work->{food_type_count},
        };
    }
    $out->{themepark}{can_operate} = (eval { $building->can_operate }) ? 1 : 0;
    $out->{themepark}{reason} = $@;
    return $out;
};

sub operate {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    $building->operate;
    return $self->view($session, $building);
}


__PACKAGE__->register_rpc_method_names(qw(operate));
no Moose;
__PACKAGE__->meta->make_immutable;

