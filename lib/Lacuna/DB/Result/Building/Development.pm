package Lacuna::DB::Result::Building::Development;

use Moose;
extends 'Lacuna::DB::Result::Building';
use Lacuna::Util qw(to_seconds);

sub subsidize_build_queue {
    my ($self) = @_;
    $self->body->tick;
    my $builds = $self->body->builds;
    while (my $build = $builds->next) {
        $build->finish_upgrade;
    }
}

sub calculate_subsidy {
    my ($self) = @_;
    my $levels = 0;
    my $builds = $self->body->builds;
    while (my $build = $builds->next) {
        $levels += $build->level + 1;
    }
    my $cost = int($levels / 3);
    $cost = 1 if $cost < 1;
    return $cost;
}

sub format_build_queue {
    my ($self) = @_;
    my @queue;
    my $builds = $self->body->builds;
    my $now = DateTime->now;
    while (my $build = $builds->next) {
        push @queue, {
            building_id         => $build->id,
            name                => $build->name,
            to_level            => ($build->level + 1),
            seconds_remaining   => to_seconds($build->upgrade_ends - $now),
            x                   => $build->x,
            y                   => $build->y,
        };
    }
    return \@queue;
}

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
};

use constant controller_class => 'Lacuna::RPC::Building::Development';

use constant max_instances_per_planet => 1;

use constant university_prereq => 1;

use constant image => 'devel';

use constant name => 'Development Ministry';

use constant food_to_build => 78;

use constant energy_to_build => 77;

use constant ore_to_build => 77;

use constant water_to_build => 78;

use constant waste_to_build => 70;

use constant time_to_build => 300;

use constant food_consumption => 10;

use constant energy_consumption => 10;

use constant ore_consumption => 4;

use constant water_consumption => 10;

use constant waste_production => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
