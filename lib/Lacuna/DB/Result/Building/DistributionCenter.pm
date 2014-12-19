package Lacuna::DB::Result::Building::DistributionCenter;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Storage));
};

use constant controller_class => 'Lacuna::RPC::Building::DistributionCenter';

use constant image => 'distributioncenter';

use constant name => 'Distribution Center';

use constant university_prereq => 19;

use constant food_to_build => 250;

use constant energy_to_build => 250;

use constant ore_to_build => 250;

use constant water_to_build => 250;

use constant waste_to_build => 500;

use constant time_to_build => 120;

use constant food_consumption => 2;

use constant energy_consumption => 4;

use constant ore_consumption => 2;

use constant water_consumption => 2;

use constant waste_production => 2;

use constant water_storage => 750;

use constant ore_storage => 750;

use constant energy_storage => 750;

use constant food_storage => 750;

use constant max_instances_per_planet => 2;

sub max_reserve_size {
    my $self = shift;
    return int($self->effective_level * 10000 * (10 ** ($self->effective_level/10+1)));
}
sub reserve_duration {
    my $self = shift;
    return $self->effective_level * 2 * 60 * 60;
}

sub can_reserve {
    my ($self) = @_;
    if ($self->effective_level < 1) {
        confess [1010, "You can't reserve until the Distribution Center is built."];
    }
    if ($self->is_working) {
        confess [1010, "The Distribution Center is busy."];
    }
    return 1;
}

sub reserve {
    my ($self, $resources) = @_;

    my $body = $self->body;
    my $total = 0;
    for my $resource ( @$resources ) {
        if ($resource->{type} ~~ [ORE_TYPES, FOOD_TYPES, 'water', 'energy']) {
            my $amount = $resource->{quantity};
            $total += $amount;
            confess [1011, "You cannot reserve negative resources."]
                if ($amount < 0);
            $body->can_spend_type($resource->{type}, $amount);
        }
        else {
            confess [1010, 'The distribution center cannot hold '.$resource->{type}.'.'];
        }
    }
    if ($total > $self->max_reserve_size) {
        confess [1009, "You may only reserve ".$self->max_reserve_size." total resources at a time."];
    }

    for my $resource ( @$resources ) {
        $body->spend_type($resource->{type}, $resource->{quantity});
    }

    $self->start_work({
        reserved    => $resources,
    }, $self->reserve_duration);

    $body->update;
    $self->update;
}

sub release_reserve {
    my $self = shift;
    unless ($self->is_working) {
        confess [1010, "There is nothing in the reserve."];
    }
    $self->finish_work->update;
}

before finish_work => sub {
    my $self = shift;
    my $body = $self->body;

    my $resources = $self->work->{reserved};
    my $food_reserve = 0;
    my $ore_reserve  = 0;
    my $resource;
    for $resource ( @$resources ) {
      $food_reserve += $resource->{quantity} if (grep { $resource->{type} eq $_ } FOOD_TYPES);
      $ore_reserve  += $resource->{quantity} if (grep { $resource->{type} eq $_ } ORE_TYPES);
    }
    my $food_res = ($food_reserve + $body->food_stored) - $body->food_capacity;
    if ($food_res > 0) { $body->spend_food($food_res + 100, 1) };
    my $ore_res = ($ore_reserve + $body->ore_stored) - $body->ore_capacity;
    if ($ore_res > 0) { $body->spend_ore($ore_res + 100) };
    for $resource ( @$resources ) {
        $body->add_type($resource->{type}, $resource->{quantity});
    }
    $body->update;
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
