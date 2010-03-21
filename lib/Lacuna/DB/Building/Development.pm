package Lacuna::DB::Building::Development;

use Moose;
extends 'Lacuna::DB::Building';

sub subsidize_build_queue {
    my ($self, $amount) = @_;
    $self->empire->spend_essentia($amount);
    my $builds = $self->simpledb->domain('build_queue')->search(where=>{body_id=>$self->body_id});
    while (my $build = $builds->next) {
        $build->date_complete->subtract(seconds=>($amount * 600));
        $build->put;
    }
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
        };
    }
    return \@queue;
}

use constant controller_class => 'Lacuna::Building::Development';

use constant max_instances_per_planet => 1;

use constant building_prereq => {'Lacuna::DB::Building::PlanetaryCommand'=>5};

use constant image => 'devel';

use constant name => 'Development Ministry';

use constant food_to_build => 70;

use constant energy_to_build => 70;

use constant ore_to_build => 70;

use constant water_to_build => 70;

use constant waste_to_build => 70;

use constant time_to_build => 600;

use constant food_consumption => 25;

use constant energy_consumption => 50;

use constant ore_consumption => 10;

use constant water_consumption => 25;

use constant waste_production => 5;


no Moose;
__PACKAGE__->meta->make_immutable;
