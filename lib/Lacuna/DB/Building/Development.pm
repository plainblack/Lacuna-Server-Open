package Lacuna::DB::Building::Development;

use Moose;
extends 'Lacuna::DB::Building';

sub subsidize_build_queue {
    my ($self) = @_;
    $self->body->tick;
    my $builds = $self->simpledb->domain('build_queue')->search(where=>{body_id=>$self->body_id});
    while (my $build = $builds->next) {
        $build->finish_build;
    }
}


sub calculate_subsidy {
    my ($self) = @_;
    my $levels = 0;
    my $builds = $self->simpledb->domain('build_queue')->search(where=>{body_id=>$self->body_id});
    while (my $build = $builds->next) {
        $levels += $build->building->level;
    }
    my $cost = int($levels / 3);
    $cost = 1 if $cost < 1;
    return $cost;
}

sub format_build_queue {
    my ($self) = @_;
    my @queue;
    my $builds = $self->body->builds;
    while (my $build = $builds->next) {
        my $target = $build->building;
        push @queue, {
            building_id         => $target->id,
            name                => $target->name,
            to_level            => ($target->level + 1),
            seconds_remaining   => $build->seconds_remaining,
            x                   => $target->x,
            y                   => $target->y,
        };
    }
    return \@queue;
}

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
};

use constant controller_class => 'Lacuna::Building::Development';

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
__PACKAGE__->meta->make_immutable;
