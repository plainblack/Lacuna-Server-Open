package Lacuna::RPC::Building::TheftTraining;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Util qw(randint);

sub app_url {
    return '/thefttraining';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::TheftTraining';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
    my $boost = (time < $empire->spy_training_boost->epoch) ? 1.5 : 1;
    my $points_per = $building->effective_level * $boost;
    $out->{spies} = {
        max_points  => 350 + $building->level * 75,
        points_per => $points_per,
        in_training     => $building->spies_in_training_count,
    };
    return $out;
};


__PACKAGE__->register_rpc_method_names();


no Moose;
__PACKAGE__->meta->make_immutable;

