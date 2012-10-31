package Lacuna::DB::Result::Building::TheftTraining;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Intelligence));
};

use constant controller_class => 'Lacuna::RPC::Building::TheftTraining';

use constant max_instances_per_planet => 1;

use constant university_prereq => 14;

use constant image => 'thefttraining';

use constant name => 'Theft Training';

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
    return Lacuna->db->resultset('Lacuna::DB::Result::Spies')
                 ->search({ empire_id => $self->body->empire_id,
                            on_body_id => $self->body_id,
                            theft_xp => {'<', 2600} });
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
    if ($spy->theft_xp >= 2600) {
        confess [1013, $spy->name." has already learned all there is to know about Theft."];
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
        my $xp_level = int(($spy->intel_xp + $spy->mayhem_xp + $spy->politics_xp + $spy->theft_xp)/200) + 1;
        my $train_time = sprintf('%.0f', 3600 * $xp_level * ((100 - (5 * $self->body->empire->management_affinity)) / 100));
        if ($self->body->happiness < 0) {
            my $unhappy_workers = abs($self->body->happiness)/100_000;
            $train_time = int($train_time * $unhappy_workers);
        }
        $train_time = 5184000 if ($train_time > 5184000); # Max time per spy is 60 days
        $train_time = 3600 if ($train_time < 3600); # Min time is 1 hour
        $costs->{time} = $train_time;
    }
    else {
        my $spies = $self->get_spies->search({ task => { in => ['Counter Espionage','Idle'] } });
        while (my $spy = $spies->next) {
            my $xp_level = int(($spy->intel_xp + $spy->mayhem_xp + $spy->politics_xp + $spy->theft_xp)/200) + 1;
            my $train_time = sprintf('%.0f', 3600 * $xp_level * ((100 - (5 * $self->body->empire->management_affinity)) / 100));
            if ($self->body->happiness < 0) {
                my $unhappy_workers = abs($self->body->happiness)/100_000;
                $train_time = int($train_time * $unhappy_workers);
            }
            $train_time = 5184000 if ($train_time > 5184000); # Max time per spy is 60 days
            $train_time = 3600 if ($train_time < 3600); # Min time is 1 hour
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
    unless ($self->theft_xp < 2600) {
        confess [1013, $spy->name." has already learned all there is to know about Theft."];
    }
    unless (defined $time_to_train) {
        $time_to_train = $self->training_costs($spy_id)->{time};
    }
    unless ($spy->task ~~ ['Counter Espionage','Idle']) {
        confess [1011, 'Spy must be idle to train.'];
    }
    my $available_on = DateTime->now;
    $available_on->add(seconds => $time_to_train );
    my $total = $spy->theft_xp + $self->level;
    $total = 2600 if $total > 2600;
    $spy->theft_xp($total);
    $spy->update_level;
    $spy->task('Training');
    $spy->available_on($available_on);
    $spy->update;
    return $self;
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
