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

sub train_spy {
    my ($self, $session_id, $building_id, $spy_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $body = $building->body;
    if ($building->level < 1) {
        confess [1013, "You can't train spies until your Theft Training Facility is completed."];
    }
    my $spy = $building->get_spy($spy_id);
    my $trained = 0;
    my $costs = $building->training_costs($spy_id);
    if (eval{$building->can_train_spy($costs)}) {
        $building->spend_resources_to_train_spy($costs);
        $building->train_spy($spy_id, $costs->{time});
        $trained++;
    }
    if ($trained) {
        $body->update;
    }
    my $quantity = 1;
    return {
        status  => $self->format_status($empire, $body),
        trained => $trained,
        not_trained => $quantity - $trained,
    };
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
    $out->{spies} = {
        training_costs  => $building->training_costs,
        in_training     => $building->spies_in_training_count,
    };
    return $out;
};


__PACKAGE__->register_rpc_method_names(qw(train_spy));


no Moose;
__PACKAGE__->meta->make_immutable;

