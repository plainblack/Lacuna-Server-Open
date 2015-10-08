package Lacuna::DB::Result::Building::Development;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use List::Util qw(max);

sub subsidize_build_queue {
    my ($self, $building) = @_;

    $self->body->tick;

    if ($building) {
        $building->finish_upgrade;
    }
    else {
        foreach my $build (@{$self->body->builds}) {
            $build->finish_upgrade;
        }
    }
}

sub calculate_subsidy {
    my ($self, $building) = @_;

    my $cost    = 0;
    if ($building) {
        $cost = 1 + # premium for targeting a single building
            max(1, int($building->level + 1) / 3);
    }
    else {
        foreach my $build (@{$self->body->builds}) {
            $cost += max(1, int($build->level + 1) / 3);
        }
    }

    return $cost;
}

sub format_build_queue {
    my ($self) = @_;
    my @queue;
    my $now = time;
    foreach my $build (@{$self->body->builds}) {
        push @queue, {
            building_id         => $build->id,
            name                => $build->name,
            to_level            => ($build->level + 1),
            seconds_remaining   => $build->upgrade_ends->epoch - $now,
            x                   => $build->x,
            y                   => $build->y,
            subsidy_cost        => $self->calculate_subsidy($build),
        };
    }
    return \@queue;
}

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Construction));
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

use constant time_to_build => 150;

use constant food_consumption => 10;

use constant energy_consumption => 10;

use constant ore_consumption => 4;

use constant water_consumption => 10;

use constant waste_production => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
