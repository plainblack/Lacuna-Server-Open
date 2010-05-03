package Lacuna::DB::Building::Intelligence;

use Moose;
extends 'Lacuna::DB::Building';

#__PACKAGE__->add_attributes(
#    spy_count                   => { isa => 'Int' },
#);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Intelligence));
};

use constant controller_class => 'Lacuna::Building::Intelligence';

use constant max_instances_per_planet => 1;

use constant university_prereq => 2;

use constant image => 'intelligence';

use constant name => 'Intelligence Ministry';

use constant food_to_build => 83;

use constant energy_to_build => 82;

use constant ore_to_build => 82;

use constant water_to_build => 83;

use constant waste_to_build => 70;

use constant time_to_build => 300;

use constant food_consumption => 70;

use constant energy_consumption => 10;

use constant ore_consumption => 2;

use constant water_consumption => 70;

use constant waste_production => 1;

sub max_spies {
    my ($self) = @_;
    return $self->level * 5;
}

has spy_count => (
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->simpledb->domain('spies')->count(where=>{from_body_id => $self->body_id});
    },
);

has latest_spy => (
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->get_spies(
            where   => {
                available_on    => ['>=', DateTime->now],
                task            => 'training',
            },
            order_by    => ['available_on'],
            consistent  => 1,
            )->next;
    },
);

sub get_spies {
    my ($self, %options) = @_;
    my %where = (from_body_id => $self->body_id);
    if ($options{where}) {
        $where{'-and'} = $options{where};
    }
    my %params = (
        where       => \%where,
        set         => {
            from_body => $self->body
        },
    );
    if ($options{order_by}) {
        $params{order_by} = $options{order_by};
    }
    if ($options{consistent}) {
        $params{consistent} = 1;
    }
    return $self->simpledb->domain('spies')->search(%params);
}

has espionage_level => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $building = $self->body->get_buildings_of_class('Lacuna::DB::Building::Espionage')->next;
        return (defined $building) ? $self->level : 0;
    },
);

has security_level => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $building = $self->body->get_buildings_of_class('Lacuna::DB::Building::Security')->next;   
        return (defined $building) ? $self->level : 0;
    },
);

has training_multiplier => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $multiplier = $self->level - $self->empire->species->deception_affinity;
        $multiplier += $self->espionage_level;
        $multiplier += $self->security_level;
        $multiplier = 1 if $multiplier < 1;
        return $multiplier;
    }
);

sub training_costs {
    my $self = shift;
    my $multiplier = $self->training_multiplier;
    my $species = $self->empire->species;
    return {
        water   => 550 * $multiplier,
        waste   => 20 * $multiplier,
        energy  => 50 * $multiplier,
        food    => 500 * $multiplier,
        ore     => 5 * $multiplier,
        time    => 430 * $multiplier / $species->management_affinity,
    };
}

sub train_spy {
    my ($self, $time_to_train) = @_;
    if ($self->spy_count < $self->max_spies) {
        unless ($time_to_train) {
            $time_to_train = $self->training_costs->{time};
        }
        my $latest = $self->latest_spy;
        my $available_on = (defined $latest) ? $latest->available_on->clone : DateTime->now;
        $available_on->add(seconds => $time_to_train );
        my $deception = $self->empire->species->deception_affinity;
        $self->simpledb->domain('spies')->insert({
            from_body_id    => $self->body_id,
            on_body_id      => $self->body_id,
            task            => 'Training',
            available_on    => $available_on,
            empire_id       => $self->empire_id,
            offense         => $self->espionage_level + $deception,
            defense         => $self->security_level + $deception,
        });
        my $count = $self->spy_count($self->spy_count + 1);
        if ($count < $self->level) {
            $self->body->add_news(20,'A source inside %s admitted that they are underprepared for the threats they face.', $self->empire->name);
        }
    }
    else {
        $self->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'training_accident.txt',
            params      => [$self->body->name],
        );
        $self->body->add_news(20,'A source inside %s confided that they lost a brave soul in a training accident today.', $self->empire->name);
    }
    return $self;
}

before delete => sub {
    my ($self) = @_;
    $self->db->domain('spies')->search(where=>{from_body_id=>$self->body_id})->delete;
};


no Moose;
__PACKAGE__->meta->make_immutable;
