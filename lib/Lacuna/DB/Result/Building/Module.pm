package Lacuna::DB::Result::Building::Module;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(GROWTH);

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
    $amount = int($amount/5) + 1;
    if ($self->efficiency <= $amount) {
        if ($self->level <= 1 && eval{$self->can_demolish}) {
            $self->demolish;
        }
        elsif ($self->level > 1 && eval{$self->can_downgrade}) {
            if (!Lacuna->cache->get('downgrade',$self->id)) {
                $self->downgrade;
                Lacuna->cache->set('downgrade',$self->id, 1, 15 * 60);
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

sub production_hour {
    my $self = shift;
    return 0 unless  $self->level;
    my $production = (GROWTH ** (  $self->level - 1));
    $production = ($production * $self->efficiency) / 100;
    return $production;
}

sub cost_to_upgrade {
    return {
        food    => 0,
        ore     => 0,
        water   => 0,
        energy  => 0,
        waste   => 0,
        time    => 60,
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

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
