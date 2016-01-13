package Lacuna::DB::Result::Building::SSLa;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(ORE_TYPES INFLATION);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Construction Ships));
};

use constant university_prereq => 20;
use constant max_instances_per_planet => 1;

use constant controller_class => 'Lacuna::RPC::Building::SSLa';

use constant image => 'ssla';

use constant name => 'Space Station Lab (A)';

use constant food_to_build => 230;

use constant energy_to_build => 350;

use constant ore_to_build => 370;

use constant water_to_build => 260;

use constant waste_to_build => 100;

use constant time_to_build => 60 * 2;

use constant food_consumption => 5;

use constant energy_consumption => 20;

use constant ore_consumption => 15;

use constant water_consumption => 6;

use constant waste_production => 20;


before 'can_demolish' => sub {
    my $self = shift;
    my $sslb = $self->body->get_building_of_class('Lacuna::DB::Result::Building::SSLb');
    if (defined $sslb) {
        confess [1013, 'You have to demolish your Space Station Lab (B) before you can demolish your Space Station Lab (A).'];
    }
};

before can_build => sub {
    my $self = shift;
    if ($self->x == 5 || $self->y == -5 || (($self->y == 1 || $self->y == 0) && ($self->x == -1 || $self->x == 0))) {
        confess [1009, 'Space Station Lab cannot be placed in that location.'];
    }
};

sub makeable_plans {
    return {
        command         => 'Lacuna::DB::Result::Building::Module::StationCommand',
        ibs             => 'Lacuna::DB::Result::Building::Module::IBS',
        art             => 'Lacuna::DB::Result::Building::Module::ArtMuseum',
        opera           => 'Lacuna::DB::Result::Building::Module::OperaHouse',
        food            => 'Lacuna::DB::Result::Building::Module::CulinaryInstitute',
        parliament      => 'Lacuna::DB::Result::Building::Module::Parliament',
        warehouse       => 'Lacuna::DB::Result::Building::Module::Warehouse',
        policestation   => 'Lacuna::DB::Result::Building::Module::PoliceStation',
    };
}

sub makeable_plans_formatted {
    my $self = shift;
    my @out;
    my $makeable_plans = $self->makeable_plans;
    while (my ($type, $class) = each %{$makeable_plans}) {
        push @out, {
            image   => $class->image,
            name    => $class->name,
            url     => $class->controller_class->app_url,
            type    => $type,
        };
    }
    @out = sort { $a->{name} cmp $b->{name} } @out;
    return \@out;
}

sub level_costs_formatted {
    my $self = shift;
    my $max = $self->max_level;
    return [] if $max == 0;
    my @costs;
    my $resource_cost = $self->plan_resource_cost;
    my $time_cost     = $self->plan_time_cost;
    foreach my $level (1..$max) {
        my $resource = $self->plan_cost_at_level($level, $resource_cost);
        push @costs, {
            level   => $level,
            ore     => $resource,
            water   => $resource,
            energy  => $resource,
            food    => $resource,
            waste   => sprintf('%.0f', $resource/2),
            time    => $self->plan_time_at_level($level, $time_cost),
        };
    }
    return \@costs;
}

has plan_resource_cost => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return 850_000;
    }
);

has plan_time_cost => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return 150;
    }
);

sub plan_time_at_level {
    my ($self, $level, $base) = @_;
    my $inflate = INFLATION - (($self->max_level + $self->body->empire->effective_manufacturing_affinity * 5)/200);
    my $time_cost = int($base * ($inflate ** $level));
    $time_cost = 15 if ($time_cost < 15);
    $time_cost = 5184000 if ($time_cost > 5184000);
    return $time_cost;
}

sub plan_cost_at_level {
    my ($self, $level, $base) = @_;
    my $inflate = INFLATION - (($self->max_level + $self->body->empire->effective_research_affinity * 5)/200);
    my $cost = int($base * ($inflate ** $level));
    return $cost;
}

has max_level => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $level = $self->effective_level;
        my $body = $self->body;
        foreach my $part (qw(b c d)) {
            my $building = $body->get_building_of_class('Lacuna::DB::Result::Building::SSL'.$part);
            if (defined $building) {
                $level = ($level > $building->effective_level) ? $building->effective_level : $level;
            }
            else {
                $level = 0;
                last;
            }
        }
        return $level;
    },
);

sub can_make_plan {
    my ($self, $type, $level) = @_;
    if ($self->is_working) {
        confess [1010, 'The Space Station Lab is already making a plan.'];
    }
    $level ||= 1;
    if ($level > $self->max_level) {
        confess [1013, 'This Space Station Lab is not a high enough level to make that plan.'];
    }
    my $makeable = $self->makeable_plans;
    unless ($type ~~ [keys %{$makeable}]) {
        confess [1009, 'Cannot make that type of plan.'];
    }
    my $resource_cost = $self->plan_cost_at_level($level, $self->plan_resource_cost);
    my $fraction = sprintf('%.0f',$resource_cost * 0.01);
    my $body = $self->body;
    foreach my $ore (ORE_TYPES) {
        if ($body->type_stored($ore) < $fraction) {
            confess [1011, 'Not enough '.$ore.' in storage. You need at least '.$fraction.'.'];
        }
    }
    foreach my $resource (qw(ore water food energy)) {
        if ($body->type_stored($resource) < $resource_cost) {
            confess [1011, 'Not enough '.$resource.' in storage. You need at least '.$resource_cost.'.'];
        }
    }
    return 1;
}

sub make_plan {
    my ($self, $type, $level) = @_;
    $level ||= 1;
    my $makeable = $self->makeable_plans;
    my $resource_cost = $self->plan_cost_at_level($level, $self->plan_resource_cost);
    my $time_cost = $self->plan_time_at_level($level, $self->plan_time_cost);
    my $body = $self->body;
    $body->spend_ore($resource_cost);
    $body->spend_water($resource_cost);
    $body->spend_food($resource_cost, 0);
    $body->spend_energy($resource_cost);
    $body->add_waste($resource_cost/4);
    $body->update;
    $self->start_work({
        class    => $makeable->{$type},
        level    => $level,
        }, $time_cost)->update;
}

before finish_work => sub {
    my $self = shift;
    my $planet = $self->body;
    $planet->add_plan($self->work->{class}, $self->work->{level});
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
