package Lacuna::DB::Result::Building::IntelTraining;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Intelligence));
};

use constant controller_class => 'Lacuna::RPC::Building::IntelTraining';

use constant max_instances_per_planet => 1;

use constant university_prereq => 12;

use constant image => 'inteltraining';

use constant name => 'Intel Training';

use constant food_to_build => 100;

use constant energy_to_build => 99;

use constant ore_to_build => 99;

use constant water_to_build => 100;

use constant waste_to_build => 84;

use constant time_to_build => 180;

use constant food_consumption => 84;

use constant energy_consumption => 12;

use constant ore_consumption => 3;

use constant water_consumption => 84;

use constant waste_production => 2;

has spies_in_training_count => (
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->get_spies->search({task=>'Training'})->count;
    },
);

sub get_spies {
    my ($self) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({ empire_id => $self->body->empire_id, on_body_id => $self->body_id });
}

sub get_spy {
    my ($self, $spy_id) = @_;
    my $spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($spy_id);
    unless (defined $spy) {
        confess [1002, 'No such spy.'];
    }
    if ($spy->empire_id ne $self->body->empire_id) {
        confess [1013, "You don't control that spy."];
    }
    if ($spy->on_body_id != $self->body->id) {
        confess [1013, "Spy must be on planet to train."];
    }
    return $spy;
}

has training_multiplier => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $multiplier = $self->level;
        $multiplier = 1 if $multiplier < 1;
        return $multiplier;
    }
);

sub training_costs {
    my $self = shift;
    my $spy_id = shift;
    my $multiplier = $self->training_multiplier;
    my $costs = {
        water   => 1100 * $multiplier,
        waste   => 40 * $multiplier,
        energy  => 100 * $multiplier,
        food    => 1000 * $multiplier,
        ore     => 10 * $multiplier,
        time    => [],
    };
    if ($spy_id) {
        my $spy = $self->get_spy($spy_id);
        my $train_time = sprintf('%.0f', 3600 * $spy->level *
                                ((100 - (5 * $self->body->empire->management_affinity)) / 100));
        $train_time = 3600 if ($train_time < 3600);
        $costs->{time} = $train_time;
    }
    else {
        my $spies = $self->get_spies->search({ task => { in => ['Counter Espionage','Idle'] } });
        while (my $spy = $spies->next) {
            my $train_time = sprintf('%.0f', 3600 * $spy->level *
                                ((100 - (5 * $self->body->empire->management_affinity)) / 100));
            $train_time = 3600 if ($train_time < 3600);
            push @{$costs->{time}}, {
                spy_id  => $spy->id,
                name    => $spy->name,
                time    => $train_time,
            };
        }
    }
    return $costs;
}

sub can_train_spy {
    my ($self, $costs) = @_;
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
    my ($self, $spy_id, $time_to_train) = @_;
    my $empire = $self->body->empire;
    my $spy = $self->get_spy($spy_id);
    unless (defined $time_to_train) {
        $time_to_train = $self->training_costs($spy_id)->{time};
    }
    unless ($spy->task ~~ ['Counter Espionage','Idle']) {
        confess [1011, 'Spy must be idle to train.'];
    }
    my $available_on = DateTime->now;
    $available_on->add(seconds => $time_to_train );
    $spy->intel_xp($spy->intel_xp + $self->level);
    $spy->update_level;
    $spy->task('Training');
    $spy->available_on($available_on);
    $spy->update;
    return $self;
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
