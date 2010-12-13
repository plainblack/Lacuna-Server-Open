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
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
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
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $building->operate;
    return $self->view($empire, $building);
}


__PACKAGE__->register_rpc_method_names(qw(operate));
no Moose;
__PACKAGE__->meta->make_immutable;

