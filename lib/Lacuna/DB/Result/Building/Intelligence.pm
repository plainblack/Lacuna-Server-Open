package Lacuna::DB::Result::Building::Intelligence;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Intelligence));
};

use constant controller_class => 'Lacuna::RPC::Building::Intelligence';

use constant max_instances_per_planet => 1;

use constant university_prereq => 2;

use constant image => 'intelligence';

use constant name => 'Intelligence Ministry';

use constant food_to_build => 83;

use constant energy_to_build => 82;

use constant ore_to_build => 82;

use constant water_to_build => 83;

use constant waste_to_build => 70;

use constant time_to_build => 150;

use constant food_consumption => 70;

use constant energy_consumption => 10;

use constant ore_consumption => 2;

use constant water_consumption => 70;

use constant waste_production => 1;

sub max_spies {
    my ($self) = @_;
# Just temporary until the major change
    return ($self->effective_level * 3);
}

has spy_count => (
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->get_spies->count;
    },
);

has spies_in_training_count => (
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->get_spies->search({task=>'Training'})->count;
    },
);

has latest_spy => (
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->get_spies->search(
            {
                task            => 'Training',
            },
            {
                order_by    => { -desc => 'available_on' }
            }
        )->first;
    },
);

sub get_spies {
    my ($self) = @_;
    return Lacuna->db->resultset('Spies')->search({ from_body_id => $self->body_id });
}

sub get_empire_spies {
    my ($self) = @_;
    return Lacuna->db->resultset('Spies')->search({ empire_id => $self->body->empire_id });
}

sub get_spy {
    my ($self, $spy_id) = @_;
    my $spy = Lacuna->db->resultset('Spies')->find($spy_id);
    unless (defined $spy) {
        confess [1002, 'No such spy.'];
    }
    if ($spy->from_body_id ne $self->body_id) {
        confess [1013, "You don't control that spy."];
    }
    return $spy;
}

has espionage_level => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $building = $self->body->get_building_of_class('Lacuna::DB::Result::Building::Espionage');
        return (defined $building) ? $building->effective_level : 0;
    },
);

has security_level => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $building = $self->body->get_building_of_class('Lacuna::DB::Result::Building::Security');   
        return (defined $building) ? $building->effective_level : 0;
    },
);

has training_multiplier => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
#        my $multiplier = $self->effective_level
        my $multiplier = 1
            - $self->body->empire->deception_affinity
            + $self->espionage_level
            + $self->security_level;
        $multiplier = 1 if $multiplier < 1;
        return $multiplier;
    }
);

sub training_costs {
    my $self = shift;
    my $multiplier = $self->training_multiplier;
    my $time_to_train = sprintf('%.0f', 2060 * $multiplier / $self->body->empire->management_affinity);
    if ($self->body->happiness < 0) {
      my $unhappy_workers = abs($self->body->happiness)/100_000;
      $time_to_train = int($time_to_train * $unhappy_workers);
    }
    $time_to_train = 5184000 if ($time_to_train > 5184000); # Max time per spy is 60 days
    $time_to_train = 300 if ($time_to_train < 300); # Min time is 5 minutes
    return {
        water   => 1100 * $multiplier,
        waste   => 40 * $multiplier,
        energy  => 100 * $multiplier,
        food    => 1000 * $multiplier,
        ore     => 10 * $multiplier,
        time    => $time_to_train,
    };
}

sub can_train_spy {
    my ($self, $costs) = @_;
    if ($self->spy_count >= $self->max_spies) {
        confess [1009, 'You already have the maximum number of spies.'];
    }
    my $body = $self->body;
    foreach my $resource (qw(water ore food energy)) {
        unless ($body->type_stored($resource) >= $costs->{$resource}) {
            confess [1011, 'Not enough '.$resource.' to train a spy.'];
        }
    }
    return 1;
}

sub spend_resources_to_train_spy {
    my ($self, $costs) = @_;
    my $body = $self->body;
    foreach my $resource (qw(water ore food energy)) {
        my $spend = 'spend_'.$resource;
        $body->$spend($costs->{$resource});
    }
    $body->add_waste($costs->{waste});
}

sub train_spy {
    my ($self, $time_to_train) = @_;
    my $empire = $self->body->empire;
    if ($self->spy_count < $self->max_spies) {
        unless ($time_to_train) {
            $time_to_train = $self->training_costs->{time};
        }
        my $latest = $self->latest_spy;
        my $available_on = (defined $latest) ? $latest->available_on->clone : DateTime->now;
        $available_on->add(seconds => $time_to_train );
        my $deception = $empire->deception_affinity * 50;
        my $spy = Lacuna->db->resultset('Spies')->new({
            from_body_id    => $self->body_id,
            on_body_id      => $self->body_id,
            task            => 'Training',
            started_assignment  => DateTime->now,
            available_on    => $available_on,
            empire_id       => $self->body->empire_id,
            offense         => ($self->espionage_level * 75) + $deception,
            defense         => ($self->security_level * 75) + $deception,
        })
        ->update_level
        ->insert;
        $self->latest_spy($spy);
        my $count = $self->spy_count($self->spy_count + 1);
        if ($count < $self->effective_level) {
            $self->body->add_news(20,'A source inside %s admitted that they are underprepared for the threats they face.', $empire->name);
        }
        if ($self->is_working) {
            $self->reschedule_work($available_on);
        }
        else {
            $self->start_work({}, $available_on->epoch - time())->update;
        }
    }
    else {
        $empire->send_predefined_message(
            tags        => ['Spies','Alert'],
            filename    => 'training_accident.txt',
            params      => [$self->body->id, $self->body->name],
        );
        $self->body->add_news(20,'A source inside %s confided that they lost a brave soul in a training accident today.', $empire->name);
    }
    return $self;
}

before delete => sub {
    my ($self) = @_;
    $self->get_spies->delete;
};

before 'can_downgrade' => sub {
    my $self = shift;
    if ($self->spy_count > ($self->max_spies -3)) {
        confess [1013, 'You must burn a spy to downgrade the Intelligence Ministry.'];
    }
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
