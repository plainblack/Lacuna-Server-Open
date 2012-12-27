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
    $empire->spend_essentia({
        amount      => $subsidy, 
        reason      => 'construction subsidy',
    });
    $empire->update;
    $building->subsidize_build_queue;
    return {
        status          => $self->format_status($session, $building->body),
        essentia_spent  => $subsidy,
    };
}

sub subsidize_one_building {

    my ($self, $args) = @_;

    if (ref($args) ne "HASH") {
        confess [1003, "You have not supplied a hash reference"];
    }
    my $empire              = $self->get_empire_by_session($args->{session_id});
    my $building            = $self->get_building($empire, $args->{building_id});
    my $scheduled_building  = Lacuna->db->resultset('Building')->find($args->{scheduled_id});
    if ($scheduled_building->body_id != $building->body_id) {
        confess [1003, "That building is not on the same planet as your development ministry."];
    }
    if (not $scheduled_building->is_upgrading) {
        confess [1000, "That building is not currently being upgraded."];
    }
    my $subsidy             = $building->calculate_subsidy($scheduled_building);

    if ($empire->essentia < $subsidy) {
        confess [1011, "You don't have enough essentia."];
    }
    $empire->spend_essentia($subsidy, 'construction subsidy');
    $empire->update;
    $building->subsidize_build_queue($scheduled_building);

    return {
        status          => $self->format_status($empire, $building->body),
        essentia_spent  => $subsidy,
    };

}

my %non_cancel = map { $_=>1 } ('Lacuna::DB::Result::Building::DeployedBleeder');

sub cancel_build {
    my ($self, $args) = @_;

    if (ref($args) ne "HASH") {
        confess [1003, "You have not supplied a hash reference"];
    }
    my $empire              = $self->get_empire_by_session($args->{session_id});
    my $building            = $self->get_building($empire, $args->{building_id});
    my $scheduled_building  = Lacuna->db->resultset('Building')->find($args->{scheduled_id});
    if ($scheduled_building->body_id != $building->body_id) {
        confess [1003, "That building is not on the same planet as your development ministry."];
    }

    my @order;
    if ($args->{cancel_all}) {
        @order = reverse @{$building->body->builds};
    }
    else {
        @order = sort { $b->upgrade_ends cmp $a->upgrade_ends } map {
            my $scheduled_id = $_;
            my $scheduled_building = ref $scheduled_id ?
                $scheduled_id :
                $self->get_building($session,$scheduled_id,nocheck_type=>1);

            if (!$scheduled_building) {
                confess [1003, "That building does not exist, or is not yours."];
            }
            if ($scheduled_building->body_id != $building->body_id) {
                confess [1003, "That building is not on the same planet as your development ministry."];
            }
            if (not $scheduled_building->is_upgrading) {
                confess [1000, "That building is not currently being ugraded."];
            }
            if ($non_cancel{$scheduled_building->class}) {
                confess [1003, "That building can not have an upgrade cancelled."];
            }
            $scheduled_building;
        } @$ids;
    }
    $_->cancel_upgrade for @order;

    return $self->view($args->{session_id}, $args->{building_id});

}

__PACKAGE__->register_rpc_method_names(qw(
    subsidize_build_queue
    cancel_build
    subsidize_one_build
));


no Moose;
__PACKAGE__->meta->make_immutable;

