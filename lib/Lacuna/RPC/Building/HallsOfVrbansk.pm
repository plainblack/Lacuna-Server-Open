package Lacuna::RPC::Building::HallsOfVrbansk;

use Moose;
use utf8;
use List::Util qw(min);

no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/hallsofvrbansk';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
    my $body = $building->body;

    my @halls = $building->get_halls;
    my $halls_placed = scalar @halls;
    my $total = $halls_placed;
    my ($plans) = grep {$_->class eq 'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk'} @{$body->plan_cache};
    if ($plans) {
        $total += $plans->quantity;
    }
    $out->{halls_available} = $total;
    return $out;
};

sub get_upgradable_buildings {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @buildings;
    my @upgradable = @{$building->get_upgradable_buildings};
    foreach my $building (@upgradable) {
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
    my @halls = $building->get_halls;
    my $halls_placed = scalar @halls;
    my $total = $halls_placed;
    my ($plans) = grep {$_->class eq 'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk'} @{$body->plan_cache};
    if ($plans) {
        $total += $plans->quantity;
    }
    return {
        buildings       => \@buildings,
        status          => $self->format_status($empire, $building->body),
        halls_available => $total,
    };
}

sub sacrifice_to_upgrade {
    my ($self, $session_id, $building_id, $upgrade_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my ($upgrade) = grep {$_->id == $upgrade_id} @{$building->body->building_cache};
    unless (defined $upgrade) {
        confess [1002, 'Could not find the building to upgrade.'];
    }
    my $is_upgradable = grep {$_->id == $upgrade->id} @{$building->get_upgradable_buildings};
    unless ($is_upgradable) {
        confess [1009, 'The Halls of Vrbansk do not have the knowledge necessary to upgrade the '.$upgrade->name];
    }
    my $needed = $upgrade->level + 1;
    
    my $body = $building->body;
    $body->has_room_in_build_queue;
    $upgrade->body($body);
    $upgrade->start_upgrade;
    # get the number of built halls
    my @halls = $building->get_halls;
    my $halls_placed = scalar @halls;
    my $total = $halls_placed;
    # and the number of plans
    my ($plans) = grep {$_->class eq 'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk'} @{$body->plan_cache};
    if ($plans) {
        $total += $plans->quantity;
    }
    if ($total < $needed) {
        confess [1009, 'The Halls of Vrbansk do not have the knowledge necessary to upgrade the '.$upgrade->name];
    }
    shift @halls if ($total > $needed); # Leave one hall standing if not needed for upgrade.
    while ($needed) {
        my $hall = shift(@halls);
        if ($hall) {
            $hall->delete
        }
        else {
            last;
        }
        $needed--;
    }
    if ($plans) {
        my $to_delete = min($plans->quantity, $needed);
        $body->delete_many_plans($plans, $to_delete);
        $needed -= $to_delete;
    }
    $body->needs_surface_refresh(1);
    $body->update;
    return { status => $self->format_status($empire, $body) };
}

__PACKAGE__->register_rpc_method_names(qw(get_upgradable_buildings sacrifice_to_upgrade));

no Moose;
__PACKAGE__->meta->make_immutable;

