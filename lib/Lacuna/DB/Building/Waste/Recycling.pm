package Lacuna::DB::Result::Building::Waste::Recycling;

use Moose;
extends 'Lacuna::DB::Result::Building::Waste';
use Lacuna::Util qw(to_seconds);

__PACKAGE__->add_columns(
    recycling_ends          => { data_type => 'datetime', is_nullable => 0, default_value => DateTime->now },
    recycling_in_progress   => { isa => 'Str', default => 0 },
    water_from_recycling    => { isa => 'Int', default => 0 },
    energy_from_recycling   => { isa => 'Int', default => 0 },
    ore_from_recycling      => { isa => 'Int', default => 0 },
);

sub recycling_seconds_remaining {
    my ($self) = @_;
    my $seconds = to_seconds($self->recycling_ends - DateTime->now);
    return ($seconds > 0) ? $seconds : 0;
}

sub can_recycle {
    my ($self, $water, $ore, $energy, $use_essentia) = @_;
    $water ||= 0;
    $ore ||= 0;
    $energy ||= 0;
    if ($self->level < 1) {
        confess [1010, "You can't recycle until the Recycling Center is built."];
    }
    if ($self->recycling_in_progress) {
        confess [1010, "The Recycling Center is busy."];
    }
    if (($water + $ore + $energy) > $self->body->waste_stored) {
        confess [1011, "You don't have that much waste in storage."];
    }
    if (defined $use_essentia && $use_essentia && !$self->empire->essentia >= 2) {
        confess [1011, "You don't have enough essentia to subsidize recycling."];
    }
    return 1;
}

sub recycle {
    my ($self, $water, $ore, $energy, $use_essentia) = @_;
    $self->can_recycle($water, $ore, $energy, $use_essentia);

    # setup
    my $body = $self->body;
    my $empire = $self->empire;    
    my $total = $water + $ore + $energy;
    
    # start
    my $seconds = $total * 10 * $self->time_cost_reduction_bonus($self->level * 2);
    $self->recycling_ends(DateTime->now->add(seconds=>$seconds));
    $self->water_from_recycling($water);
    $self->ore_from_recycling($ore);
    $self->energy_from_recycling($energy);

    # spend
    $body->spend_waste($total);
    if ($use_essentia) {
        $empire->spend_essentia(2);
        $self->finish_recycling;
    }
    else {
        $body->put;
        $empire->trigger_full_update;
        $self->recycling_in_progress(1);
        $self->put;
    }
}

sub finish_recycling {
    my ($self) = @_;
    if ($self->recycling_in_progress) {
        $self->recycling_in_progress(0);
        $self->put;
    }
    my $planet = $self->body;
    $planet->add_water($self->water_from_recycling);
    $planet->add_ore($self->ore_from_recycling);
    $planet->add_energy($self->energy_from_recycling);
    $planet->put;
    $self->empire->trigger_full_update;
}

sub check_recycling_over {
    my ($self) = @_;
    if ($self->recycling_in_progress) {
        if ($self->recycling_ends < DateTime->now) {
            $self->finish_recycling;
        }
    }
}


around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Water Ore));
};

use constant controller_class => 'Lacuna::Building::WasteRecycling';

use constant image => 'wasterecycling';

use constant university_prereq => 3;

use constant name => 'Waste Recycling Center';

use constant food_to_build => 75;

use constant energy_to_build => 75;

use constant ore_to_build => 70;

use constant water_to_build => 100;

use constant waste_to_build => 50;

use constant time_to_build => 280;

use constant food_consumption => 15;

use constant energy_consumption => 5;

use constant ore_consumption => 1;

use constant water_consumption => 15;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
