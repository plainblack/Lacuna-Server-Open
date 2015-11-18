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
    my ($orig, $self, $session_id, $building_id) = @_;

    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id, skip_offline => 1 });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $out = $orig->($self, $session, $building);
    $out->{build_queue} = $building->format_build_queue;
    $out->{subsidy_cost} = $building->calculate_subsidy;
    return $out;
};

sub subsidize_build_queue {
    my ($self, $session_id, $building_id) = @_;

    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional development ministry!"];
    }
    my $subsidy = $building->calculate_subsidy;
    if ($empire->essentia < $subsidy) {
        confess [1011, "You don't have enough essentia."];
    }
    $empire->spend_essentia({
        amount      => $subsidy, 
        reason      => 'construction subsidy',
    });
    $empire->update;
    $building->subsidize_build_queue;
    return {
        status          => $self->format_status($empire, $building->body),
        essentia_spent  => $subsidy,
    };
}

sub subsidize_one_build {
    my ($self, $args) = @_;

    if (ref($args) ne "HASH") {
        confess [1000, "You have not supplied a hash reference"];
    }
    my $session  = $self->get_session({session_id => $args->{session_id}, building_id => $args->{building_id} });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    unless ($building->effective_level > 0 and $building->effective_efficiency == 100) {
        confess [1003, "You must have a functional development ministry!"];
    }
    my $scheduled_building  = Lacuna->db->resultset('Building')->find({id => $args->{scheduled_id}});
    if (not $scheduled_building) {
        confess [1003, "Cannot find that building."];
    }
    if ($scheduled_building->body_id != $building->body_id) {
        confess [1003, "That building is not on the same planet as your development ministry."];
    }
    if (not $scheduled_building->is_upgrading) {
        confess [1000, "That building is not currently being ugraded."];
    }
    my $subsidy = $building->calculate_subsidy($scheduled_building);

    if ($empire->essentia < $subsidy) {
        confess [1011, "You don't have enough essentia."];
    }
    $empire->spend_essentia({
        amount  => $subsidy, 
        reason  => 'construction subsidy',
    });
    $empire->update;
    $building->subsidize_build_queue($scheduled_building);

    return {
        status          => $self->format_status($empire, $building->body),
        essentia_spent  => $subsidy,
    };
}

sub cancel_build {
    my ($self, $args) = @_;

    if (ref($args) ne "HASH") {
        confess [1000, "You have not supplied a hash reference"];
    }
    my $session  = $self->get_session({session_id => $args->{session_id}, building_id => $args->{building_id} });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $scheduled_building  = $self->get_building($session,$args->{scheduled_id},nocheck_type=>1);
    if (!$scheduled_building) {
        confess [1003, "That building does not exist, or is not yours."];
    }
    if ($scheduled_building->body_id != $building->body_id) {
        confess [1003, "That building is not on the same planet as your development ministry."];
    }
    if (not $scheduled_building->is_upgrading) {
        confess [1000, "That building is not currently being ugraded."];
    }
    my @non_cancel = ('Lacuna::DB::Result::Building::DeployedBleeder');
    if (grep { $scheduled_building->class eq "$_" } @non_cancel) {
        confess [1003, "That building can not have an upgrade cancelled."];
    }
    $scheduled_building->cancel_upgrade;

    return $self->view($args->{session_id}, $args->{building_id});

}


__PACKAGE__->register_rpc_method_names(qw(
    subsidize_build_queue
    cancel_build
    subsidize_one_build
));


no Moose;
__PACKAGE__->meta->make_immutable;

