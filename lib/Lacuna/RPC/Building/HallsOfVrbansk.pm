package Lacuna::RPC::Building::HallsOfVrbansk;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/hallsofvrbansk';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk';
}

sub get_upgradable_buildings {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @buildings;
    my $upgradable = $building->get_upgradable_buildings;
    while (my $building = $upgradable->next) {
        next if ($building->level > $empire->university_level);
        push @buildings, {
            id      => $building->id,
            name    => $building->name,
            x       => $building->x,
            y       => $building->y,
            level   => $building->level,
            image   => $building->image_level,
            url     => $building->controller_class->app_url,
        };
    }
    return {
        buildings   => \@buildings,
        status      => $self->format_status($empire, $building->body),
    };
}

sub sacrifice_to_upgrade {
    my ($self, $session_id, $building_id, $upgrade_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $upgrade = $building->body->buildings->find($upgrade_id);
    unless (defined $upgrade) {
        confess [1002, 'Could not find the building to upgrade.'];
    }
    my @upgradable = $building->get_upgradable_buildings->get_column('id')->all;
    unless ($upgrade->id ~~ \@upgradable) {
        confess [1009, 'The Halls of Vrbansk do not have the knowledge necessary to upgrade the '.$upgrade->name];
    }
    my $body = $building->body;
    $upgrade->body($body);
    $upgrade->start_upgrade;
    # get the number of built halls
    my @halls = $building->get_halls->search(undef, {rows => $upgrade->level + 1});
    # get the remaining plans
    my $plans_needed = $upgrade->level + 1 - scalar @halls;
    my @plans;
    if ($plans_needed > 0) {
        @plans = $body->plans->search({
            class => 'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk'
        },{rows => $plans_needed}
        );
    }
    foreach my $hall (@halls) {
        $hall->delete;
    }
    foreach my $plan (@plans) {
        $plan->delete;
    }
    $body->needs_surface_refresh(1);
    $body->update;
    return { status => $self->format_status($empire, $body) };
}

__PACKAGE__->register_rpc_method_names(qw(get_upgradable_buildings sacrifice_to_upgrade));

no Moose;
__PACKAGE__->meta->make_immutable;

