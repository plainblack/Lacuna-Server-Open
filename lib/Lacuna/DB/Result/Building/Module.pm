package Lacuna::DB::Result::Building::Module;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(GROWTH);
use List::Util qw(max);

with 'Lacuna::Role::Building::IgnoresUniversityLevel';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
};

sub image_level {
    my $self = shift;
    return $self->image;
}

use constant energy_consumption => 80;
use constant water_consumption => 80;
use constant food_consumption => 80;
use constant ore_consumption => 80;
use constant energy_to_build => 500;
use constant food_to_build => 100;
use constant ore_to_build => 500;
use constant water_to_build => 150;

sub sortable_name {
    '75'.shift->name
}

around spend_efficiency => sub {
    my ($orig, $self, $amount) = @_;
    if ($self->efficiency <= $amount) {
        if ($self->level <= 1 && eval{$self->can_demolish}) {
            $self->demolish;
        }
        elsif ($self->level > 1 && eval{$self->can_downgrade}) {
            if (!Lacuna->cache->get('downgrade',$self->id)) {
                $self->downgrade;
                Lacuna->cache->set('downgrade',$self->id, 1, 5 * 60);
            }
            else {
                $amount = $self->efficiency - 1;
                $orig->($self, $amount);
            }
        }
        else {
            $orig->($self, $amount);
        }
    }
    else {
        $orig->($self, $amount);
    }
    return $self;
};

sub cost_to_upgrade {
    my ($self) = @_;
    my $time_cost = max($self->level, 15);
    return {
        food    => 0,
        ore     => 0,
        water   => 0,
        energy  => 0,
        waste   => 0,
        time    => $time_cost,
    };
}

before can_upgrade => sub {
    my $self = shift;
    my $plan = $self->body->get_plan($self->class, $self->level + 1);
    if (defined $plan) {
        my $command = $self->body->command;
        if ($command->level >= $self->level + 1 || $self->isa('Lacuna::DB::Result::Building::Module::StationCommand')) {
            return 1;
        }
        else {
            confess [1013, 'A module cannot be upgraded past the level of station command.'];
        }
    }
    else {
        confess [1013, 'You need a plan to upgrade this module.'];
    }
};

sub can_build_on {
    my $self = shift;
    unless ($self->body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        confess [1009, 'Can only be built on space stations.'];
    }
    return 1;
}

around demolish => sub {
    my ($orig, $self) = @_;
    my $body = $self->body;
    my $empire = $body->empire;
    $orig->($self);
    if (! defined $body->command && ! defined $body->parliament) {
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'space_station_destroyed.txt',
            params      => [$body->id, $body->name],
        );
#        $body->sanitize;
    }
};

sub food_capacity {
    my ($self) = @_;
    my $base = $self->food_storage * $self->production_hour;
    return 0 if $base == 0;
    my $empire = $self->body->empire;
    return 1 unless defined $empire;
    return sprintf('%.0f', $base );
}

sub energy_capacity {
    my ($self) = @_;
    my $base = $self->energy_storage * $self->production_hour;
    return 0 if $base == 0;
    my $empire = $self->body->empire;
    return 1 unless defined $empire;
    return sprintf('%.0f', $base );
}

sub ore_capacity {
    my ($self) = @_;
    my $base = $self->ore_storage * $self->production_hour;
    return 0 if $base == 0;
    my $empire = $self->body->empire;
    return 1 unless defined $empire;
    return sprintf('%.0f', $base );
}

sub water_capacity {
    my ($self) = @_;
    my $base = $self->water_storage * $self->production_hour;
    return 0 if $base == 0;
    my $empire = $self->body->empire;
    return 1 unless defined $empire;
    return sprintf('%.0f', $base );
}

sub waste_capacity {
    my ($self) = @_;
    my $base = $self->waste_storage * $self->production_hour;
    return 0 if $base == 0;
    my $empire = $self->body->empire;
    return 1 unless defined $empire;
    return sprintf('%.0f', $base );
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
