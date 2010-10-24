package Lacuna::DB::Result::Building::MissionCommand;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
};

use constant controller_class => 'Lacuna::RPC::Building::MissionCommand';

use constant university_prereq => 7;

use constant max_instances_per_planet => 1;

use constant image => 'missioncommand';

use constant name => 'Mission Command';

use constant food_to_build => 85;

use constant energy_to_build => 90;

use constant ore_to_build => 110;

use constant water_to_build => 90;

use constant waste_to_build => 40;

use constant time_to_build => 120;

use constant food_consumption => 7;

use constant energy_consumption => 10;

use constant ore_consumption => 3;

use constant water_consumption => 10;

use constant waste_production => 2;

sub get_missions {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @missions;
    my $missions = $building->missions;
    while (my $mission = $missions->next) {
        next if $mission->params->max_university_level < $empire->university_level;
        push @missions, {
            id          => $mission->id,
            name        => $mission->name,
            description => $mission->description,
            objectives  => $mission->format_objectives,
            rewards     => $mission->format_rewards,
        };
    }
    return {
        status      => $self->format_status($empire, $building->body),
        missions    => \@missions,
    };
}

__PACKAGE__->register_rpc_method_names(qw(get_missions));

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
