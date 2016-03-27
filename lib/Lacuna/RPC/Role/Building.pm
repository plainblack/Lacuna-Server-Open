package Lacuna::RPC::Role::Building;

use Moose::Role;

# Return a 'buildings' hash suitable for output to the RPC
#
sub out_buildings {
    my ($self, $body) = @_;

    my $out;

    my @buildings = @{$body->building_cache};
    foreach my $building (@buildings) {
        $out->{$building->id} = {
            url     => $building->controller_class->app_url,
            image   => $building->image_level,
            name    => $building->name,
            x       => $building->x,
            y       => $building->y,
            level   => $building->level,
            efficiency => $building->efficiency,
        };
        if ($building->is_upgrading) {
            $out->{$building->id}{pending_build} = $building->upgrade_status;
        }
        if ($building->is_working) {
            $out->{$building->id}{work} = {
                seconds_remaining   => $building->work_seconds_remaining,
                start               => $building->work_started_formatted,
                end                 => $building->work_ends_formatted,
            };
        }
        if ($building->efficiency < 100) {
            $out->{$building->id}{repair_costs} = $building->get_repair_costs;
        }
    }
    return $out;
}


1;
