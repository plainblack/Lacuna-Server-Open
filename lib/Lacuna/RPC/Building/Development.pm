package Lacuna::RPC::Building::Development;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/development';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Development';
}

around 'view' => sub {
    my $orig = shift;
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id}, skip_offline => 1);
    my $out         = $orig->($self, $empire, $building);
    $out->{build_queue}     = $building->format_build_queue;
    $out->{subsidy_cost}    = $building->calculate_subsidy;
    return $out;
};

sub subsidize_build_queue {
    my $self = shift;
    my $args = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id      => $args,
            building_id     => shift,
        };
    }
    my $empire      = $self->get_empire_by_session($args->{session_id});
    my $building    = $self->get_building($empire, $args->{building_id});
    my $subsidy     = $building->calculate_subsidy;

    if ($empire->essentia < $subsidy) {
        confess [1011, "You don't have enough essentia."];
    }
    $empire->spend_essentia($subsidy, 'construction subsidy');
    $empire->update;
    $building->subsidize_build_queue;
    return {
        status          => $self->format_status($empire, $building->body),
        essentia_spent  => $subsidy,
    };
}

__PACKAGE__->register_rpc_method_names(qw(
    subsidize_build_queue
));


no Moose;
__PACKAGE__->meta->make_immutable;

