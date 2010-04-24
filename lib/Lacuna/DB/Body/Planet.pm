package Lacuna::DB::Body::Planet;

use Moose;
extends 'Lacuna::DB::Body';
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use List::Util qw(shuffle);
use Lacuna::Util qw(to_seconds randint);
use DateTime;
no warnings 'uninitialized';

__PACKAGE__->add_attributes(
    size                            => { isa => 'Int' },
    empire_id                       => { isa => 'Str', default=>'None' },
    last_tick                       => { isa => 'DateTime'},
    building_count                  => { isa => 'Int', default=>0 },
    happiness_hour                  => { isa => 'Int', default=>0 },
    happiness                       => { isa => 'Int', default=>0 },
    waste_hour                      => { isa => 'Int', default=>0 },
    waste_stored                    => { isa => 'Int', default=>0 },
    waste_capacity                  => { isa => 'Int', default=>0 },
    energy_hour                     => { isa => 'Int', default=>0 },
    energy_stored                   => { isa => 'Int', default=>0 },
    energy_capacity                 => { isa => 'Int', default=>0 },
    water_hour                      => { isa => 'Int', default=>0 },
    water_stored                    => { isa => 'Int', default=>0 },
    water_capacity                  => { isa => 'Int', default=>0 },
    ore_capacity                    => { isa => 'Int', default=>0 },
    rutile_stored                   => { isa => 'Int', default=>0 },
    chromite_stored                 => { isa => 'Int', default=>0 },
    chalcopyrite_stored             => { isa => 'Int', default=>0 },
    galena_stored                   => { isa => 'Int', default=>0 },
    gold_stored                     => { isa => 'Int', default=>0 },
    uraninite_stored                => { isa => 'Int', default=>0 },
    bauxite_stored                  => { isa => 'Int', default=>0 },
    goethite_stored                 => { isa => 'Int', default=>0 },
    halite_stored                   => { isa => 'Int', default=>0 },
    gypsum_stored                   => { isa => 'Int', default=>0 },
    trona_stored                    => { isa => 'Int', default=>0 },
    kerogen_stored                  => { isa => 'Int', default=>0 },
    methane_stored                  => { isa => 'Int', default=>0 },
    anthracite_stored               => { isa => 'Int', default=>0 },
    sulfur_stored                   => { isa => 'Int', default=>0 },
    zircon_stored                   => { isa => 'Int', default=>0 },
    monazite_stored                 => { isa => 'Int', default=>0 },
    fluorite_stored                 => { isa => 'Int', default=>0 },
    beryl_stored                    => { isa => 'Int', default=>0 },
    magnetite_stored                => { isa => 'Int', default=>0 },
    ore_hour                        => { isa => 'Int', default=>0 },
    food_capacity                   => { isa => 'Int', default=>0 },
    food_consumption_hour           => { isa => 'Int', default=>0 },
    lapis_production_hour           => { isa => 'Int', default=>0 },
    potato_production_hour          => { isa => 'Int', default=>0 },
    apple_production_hour           => { isa => 'Int', default=>0 },
    root_production_hour            => { isa => 'Int', default=>0 },
    corn_production_hour            => { isa => 'Int', default=>0 },
    cider_production_hour           => { isa => 'Int', default=>0 },
    wheat_production_hour           => { isa => 'Int', default=>0 },
    bread_production_hour           => { isa => 'Int', default=>0 },
    soup_production_hour            => { isa => 'Int', default=>0 },
    chip_production_hour            => { isa => 'Int', default=>0 },
    pie_production_hour             => { isa => 'Int', default=>0 },
    pancake_production_hour         => { isa => 'Int', default=>0 },
    milk_production_hour            => { isa => 'Int', default=>0 },
    meal_production_hour            => { isa => 'Int', default=>0 },
    algae_production_hour           => { isa => 'Int', default=>0 },
    syrup_production_hour           => { isa => 'Int', default=>0 },
    fungus_production_hour          => { isa => 'Int', default=>0 },
    burger_production_hour          => { isa => 'Int', default=>0 },
    shake_production_hour           => { isa => 'Int', default=>0 },
    beetle_production_hour          => { isa => 'Int', default=>0 },
    bean_production_hour            => { isa => 'Int', default=>0 },
    bean_stored                     => { isa => 'Int', default=>0 },
    lapis_stored                    => { isa => 'Int', default=>0 },
    potato_stored                   => { isa => 'Int', default=>0 },
    apple_stored                    => { isa => 'Int', default=>0 },
    root_stored                     => { isa => 'Int', default=>0 },
    corn_stored                     => { isa => 'Int', default=>0 },
    cider_stored                    => { isa => 'Int', default=>0 },
    wheat_stored                    => { isa => 'Int', default=>0 },
    bread_stored                    => { isa => 'Int', default=>0 },
    soup_stored                     => { isa => 'Int', default=>0 },
    chip_stored                     => { isa => 'Int', default=>0 },
    pie_stored                      => { isa => 'Int', default=>0 },
    pancake_stored                  => { isa => 'Int', default=>0 },
    milk_stored                     => { isa => 'Int', default=>0 },
    meal_stored                     => { isa => 'Int', default=>0 },
    algae_stored                    => { isa => 'Int', default=>0 },
    syrup_stored                    => { isa => 'Int', default=>0 },
    fungus_stored                   => { isa => 'Int', default=>0 },
    burger_stored                   => { isa => 'Int', default=>0 },
    shake_stored                    => { isa => 'Int', default=>0 },
    beetle_stored                   => { isa => 'Int', default=>0 },
    freebies                        => { isa => 'HashRef' },
    boost_enabled                   => { isa => 'Str', default=>0 },
    needs_recalc                    => { isa => 'Str', default=>0 },
);

# RELATIONSHIPS

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');
__PACKAGE__->has_many('regular_buildings','Lacuna::DB::Building','body_id', mate => 'body');
__PACKAGE__->has_many('food_buildings','Lacuna::DB::Building::Food','body_id', mate => 'body');
__PACKAGE__->has_many('water_buildings','Lacuna::DB::Building::Water','body_id', mate => 'body');
__PACKAGE__->has_many('waste_buildings','Lacuna::DB::Building::Waste','body_id', mate => 'body');
__PACKAGE__->has_many('ore_buildings','Lacuna::DB::Building::Ore','body_id', mate => 'body');
__PACKAGE__->has_many('energy_buildings','Lacuna::DB::Building::Energy','body_id', mate => 'body');
__PACKAGE__->has_many('permanent_buildings','Lacuna::DB::Building::Permanent','body_id', mate => 'body');

sub builds { 
    my ($self, $where, $reverse) = @_;
    my $order = 'date_complete';
    if ($reverse) {
        $order = [$order];
    }
    $where->{body_id} = $self->id;
    $where->{date_complete} = ['>',DateTime->now->subtract(years=>100)] unless exists $where->{date_complete};
    return $self->simpledb->domain('Lacuna::DB::BuildQueue')->search(
        where       => $where,
        order_by    => $order,
        consistent  => 1,
        set         => {
            body  => $self,
        },
    );
}

sub ships_travelling { 
    my ($self, $where, $reverse) = @_;
    my $order = 'date_arrives';
    if ($reverse) {
        $order = [$order];
    }
    $where->{body_id} = $self->id;
    $where->{date_arrives} = ['>',DateTime->now->subtract(years=>100)] unless exists $where->{date_arrives};
    return $self->simpledb->domain('Lacuna::DB::TravelQueue')->search(
        where       => $where,
        order_by    => $order,
        consistent  => 1,
        set         => {
            body    => $self,
        },
    );
}

# SPIES

has determine_espionage => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $steal = my $sabotage = my $interception = my $rebel = my $hack = my $intel = 0;
        my (@thieves, @saboteurs, @interceptors, @spies, @hackers, @rebels);
        my $spies = $self->simpledb->domain('spies')->search(
            where => {
                on_body_id  => $self->id,
                task        => ['in', 'Incite Rebellion', 'Hack Networks', 'Appropriate Technology', 'Sabotage Infrastructure','Capture Spies','Gather Intelligence'],
            }
        );
        while (my $spy = $spies->next) {
            if ($spy->task eq 'Sabotage Infrastructure') {
                $sabotage += $spy->offense;
                push @saboteurs, $spy;
            }
            elsif ($spy->task eq 'Appropriate Technology') {
                $steal += $spy->offense;
                push @thieves, $spy;
            }
            elsif ($spy->task eq 'Gather Intelligence') {
                $intel += $spy->offense unless ($spy->empire_id eq $self->empire_id);
                push @spies, $spy;
            }
            elsif ($spy->task eq 'Incite Rebellion') {
                $rebel += $spy->offense;
                push @rebels, $spy;
            }
            elsif ($spy->task eq 'Hack Networks') {
                $hack += $spy->offense unless ($spy->empire_id eq $self->empire_id);
                push @hackers, $spy;
            }
            elsif ($spy->task eq 'Capture Spies') {
                $interception += $spy->defense;
                push @interceptors, $spy;
            }
        }
        $self->thieves(\@thieves);
        $self->theft_score( $steal );
        $self->hackers(\@hackers);
        $self->hack_score( $hack );
        $self->rebels(\@rebels);
        $self->rebel_score( $rebel );
        $self->investigators(\@spies);
        $self->intel_score( $intel );
        $self->saboteurs(\@saboteurs);
        $self->sabotage_score( $sabotage );
        $self->interceptors(\@interceptors);
        $self->interception_score( $interception );
        return 1;
    },
);

sub kill_a_spy {
    my ($self, $spy, $interceptor) = @_;
    $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'we_killed_a_spy.txt',
        params      => [$self->name, $interceptor->name],
        from        => $interceptor->empire,
    );
    $spy->kill($self);
}

sub capture_a_spy {
    my ($self, $spy, $interceptor) = @_;
    $spy->available_on(DateTime->now->add(months=>1));
    $spy->task('Captured');
    $spy->put;
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'spy_captured.txt',
        params      => [$self->name, $spy->name],
    );
    $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'we_captured_a_spy.txt',
        params      => [$self->name, $interceptor->name],
        from        => $interceptor->empire,
    );
}

sub miss_a_spy {
    my ($self, $spy, $interceptor) = @_;
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'narrow_escape.txt',
        params      => [$self->empire->name, $spy->name],
    );
    $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'we_missed_a_spy.txt',
        params      => [$self->name, $interceptor->name],
        from        => $interceptor->empire,
    );
}

sub defeat_theft {
    my ($self) = @_;
    if ($self->chance_of_theft > 0) {
        my $event = randint(1,100);
        my $spy = $self->thieves->[0];
        my $interceptor = $self->interceptors->[0];
        if ($event < 5) {
            $self->theft_score( $self->theft_score - $spy->offense );
            $self->kill_a_spy($spy, $interceptor);
            delete $self->thieves->[0];
            $self->add_news(70,'%s police caught and killed a thief on %s during the commission of the crime.', $self->empire->name, $self->name);
        }
        elsif ($event < 40) {
            $self->theft_score( $self->theft_score - $spy->offense );
            $self->capture_a_spy($spy, $interceptor);
            delete $self->thieves->[0];
            $self->add_news(40,'%s announced the incarceration of a thief on %s today.', $self->empire->name, $self->name);
        }
        else {
            $self->miss_a_spy($spy, $interceptor);
            $self->add_news(20,'A thief evaded %s authorities on %s. Citizens are warned to lock their doors.', $self->empire->name, $self->name);
        }
    }
}

sub defeat_sabotage {
    my ($self) = @_;
    if ($self->chance_of_sabotage > 0) {
        my $event = randint(1,100);
        my $spy = $self->saboteurs->[0];
        my $interceptor = $self->interceptors->[0];
        if ($event < 10) {
            $self->sabotage_score( $self->sabotage_score - $spy->offense );
            $self->kill_a_spy($spy, $interceptor);
            delete $self->saboteurs->[0];
            $self->add_news(70,'%s told us that a lone saboteur was killed on %s before he could carry out his plot.', $self->empire->name, $self->name);
        }
        elsif ($event < 50) {
            $self->sabotage_score( $self->sabotage_score - $spy->offense );
            $self->capture_a_spy($spy, $interceptor);
            delete $self->saboteurs->[0];
            $self->add_news(40,'A saboteur was apprehended on %s today by %s authorities.', $self->name, $self->empire->name);
        }
        else {
            $self->miss_a_spy($spy, $interceptor);
            $self->add_news(20,'%s authorities on %s are conducting a manhunt for a suspected saboteur.', $self->empire->name, $self->name);
        }
    }
}

sub defeat_rebellion {
    my ($self) = @_;
    if ($self->chance_of_rebellion > 0) {
        my $event = randint(1,100);
        my $spy = $self->rebels->[0];
        my $interceptor = $self->interceptors->[0];
        if ($event < 10) {
            $self->rebel_score( $self->rebel_score - $spy->offense );
            $self->kill_a_spy($spy, $interceptor);
            $self->add_news(80,'The leader of the rebellion to overthrow %s was killed in a firefight today on %s.', $self->empire->name, $self->name);
            delete $self->rebels->[0];
        }
        elsif ($event < 35) {
            $self->rebel_score( $self->rebel_score - $spy->offense );
            $self->capture_a_spy($spy, $interceptor);
            $self->add_news(50,'Police say they have crushed the rebellion on %s by apprehending %s.', $self->name, $spy->name);
            delete $self->rebels->[0];
        }
        else {
            $self->miss_a_spy($spy, $interceptor);
            $self->add_news(20,'The rebel leader, known as %s, is still eluding authorities on %s at this hour.', $spy->name, $self->name);
        }
    }
}

sub defeat_hack {
    my ($self) = @_;
    if ($self->chance_of_hack > 0) {
        my $spy = $self->hackers->[0];
        return undef if ($spy->empire_id eq $self->empire_id); # don't catch ourselves
        my $interceptor = $self->interceptors->[0];
        my $event = randint(1,100);
        if ($event < 5) {
            $self->hack_score( $self->hack_score - $spy->offense );
            $self->kill_a_spy($spy, $interceptor);
            $self->add_news(60,'A suspected hacker, age '.randint(16,60).', was found dead in his home today on %s.', $self->name);
            delete $self->hackers->[0];
        }
        elsif ($event < 30) {
            $self->hack_score( $self->hack_score - $spy->offense );
            $self->capture_a_spy($spy, $interceptor);
            $self->add_news(30,'Alleged hacker %s is awaiting arraignment on %s today.', $spy->name, $self->name);
            delete $self->hackers->[0];
        }
        else {
            $self->miss_a_spy($spy, $interceptor);
            $self->add_news(10,'Identity theft has become a real problem on %s.', $self->name);
        }
    }
}

sub defeat_intel {
    my ($self) = @_;
    if ($self->chance_of_intel > 0) {
        my $spy = $self->investigators->[0];
        return undef if ($spy->empire_id eq $self->empire_id); # don't catch ourselves
        my $interceptor = $self->interceptors->[0];
        my $event = randint(1,100);
        if ($event < 5) {
            $self->intel_score( $self->intel_score - $spy->offense );
            $self->kill_a_spy($spy, $interceptor);
            $self->add_news(60,'A suspected spy known only as %s was killed in a struggle with police on %s today.', $spy->name, $self->name);
            delete $self->investigators->[0];
        }
        elsif ($event < 15) {
            $self->intel_score( $self->intel_score - $spy->offense );
            $self->capture_a_spy($spy, $interceptor);
            $self->add_news(30,'An individual is behing held for questioning on %s at this hour for looking suspicious.', $self->name);
            delete $self->investigators->[0];
        }
        else {
            $self->miss_a_spy($spy, $interceptor);
            $self->add_news(10,'Corporate espionage has become a real problem on %s.', $self->name);
        }
    }
}

sub pick_a_spy_per_empire {
    my ($self, $spies) = @_;
    my %empires;
    foreach my $spy (@{$spies}) {
        unless (exists $empires{$spy->empire_id}) {
            $empires{$spy->empire_id} = $spy;
        }
    }
    return values %empires;
}

sub chance_of_theft {
    my $self = shift;
    $self->determine_espionage;
    my $chance = $self->theft_score - $self->interception_score;
    return ($chance > 90) ? 90 : $chance;
}

sub check_theft {
    my $self = shift;
    return ($self->chance_of_theft > randint(1,100));
}

has theft_score => (
    is      => 'rw',
    default => 0,
);

has thieves => (
    is      => 'rw',
    default => sub { [] },
);

sub chance_of_sabotage {
    my $self = shift;
    $self->determine_espionage;
    my $chance = $self->sabotage_score - $self->interception_score;
    return ($chance > 80) ? 80 : $chance;
}

sub check_sabotage {
    my $self = shift;
    return ($self->chance_of_sabotage > randint(1,100));
}

has saboteurs => (
    is      => 'rw',
    default => sub { [] },
);

has sabotage_score => (
    is      => 'rw',
    default => 0,
);

sub chance_of_hack {
    my $self = shift;
    $self->determine_espionage;
    my $chance = $self->hack_score - $self->interception_score;
    return ($chance > 70) ? 70 : $chance;
}

sub check_hack {
    my $self = shift;
    return ($self->chance_of_hack > randint(1,100));
}

has hackers => (
    is      => 'rw',
    default => sub { [] },
);

has hack_score => (
    is      => 'rw',
    default => 0,
);

sub chance_of_rebellion {
    my $self = shift;
    $self->determine_espionage;
    my $chance = $self->rebel_score - $self->interception_score;
    return ($chance > 50) ? 50 : $chance;
}

sub check_rebellion {
    my $self = shift;
    return ($self->chance_of_rebellion > randint(1,100));
}

has rebels => (
    is      => 'rw',
    default => sub { [] },
);

has rebel_score => (
    is      => 'rw',
    default => 0,
);

sub chance_of_intel {
    my $self = shift;
    $self->determine_espionage;
    my $chance = $self->intel_score - $self->interception_score;
    return ($chance > 90) ? 90 : $chance;
}

sub check_intel {
    my $self = shift;
    return ($self->chance_of_intel > randint(1,100));
}

has investigators => (
    is      => 'rw',
    default => sub { [] },
);

has intel_score => (
    is      => 'rw',
    default => 0,
);

has interception_score => (
    is      => 'rw',
    default => 0,
);

has interceptors => (
    is      => 'rw',
    default => sub { [] },
);



# FREEBIES
sub get_freebie {
    my ($self, $class) = @_;
    return $self->freebies->{$class} || 0;
}

sub add_freebie {
    my ($self, $class, $level) = @_;
    my $freebies = $self->freebies;
    $freebies->{$class} = $level;
    $self->freebies($freebies);
    return $self;
}

sub spend_freebie {
    my ($self, $class) = @_;
    my $freebies = $self->freebies;
    delete $freebies->{$class};
    $self->freebies($freebies);
    return $self;
}

sub sanitize {
    my ($self) = @_;
    foreach my $type (qw(food regular water waste ore energy)) {
        my $method = $type.'_buildings';
        $self->$method->delete;
    }
    my @attributes = qw(    building_count happiness_hour happiness waste_hour waste_stored waste_capacity
        energy_hour energy_stored energy_capacity water_hour water_stored water_capacity ore_capacity
        rutile_stored chromite_stored chalcopyrite_stored galena_stored gold_stored uraninite_stored bauxite_stored
        goethite_stored halite_stored gypsum_stored trona_stored kerogen_stored methane_stored anthracite_stored
        sulfur_stored zircon_stored monazite_stored fluorite_stored beryl_stored magnetite_stored ore_hour
        food_capacity food_consumption_hour lapis_production_hour potato_production_hour apple_production_hour
        root_production_hour corn_production_hour cider_production_hour wheat_production_hour bread_production_hour
        soup_production_hour chip_production_hour pie_production_hour pancake_production_hour milk_production_hour
        meal_production_hour algae_production_hour syrup_production_hour fungus_production_hour burger_production_hour
        shake_production_hour beetle_production_hour lapis_stored potato_stored apple_stored root_stored corn_stored
        cider_stored wheat_stored bread_stored soup_stored chip_stored pie_stored pancake_stored milk_stored meal_stored
        algae_stored syrup_stored fungus_stored burger_stored shake_stored beetle_stored bean_production_hour bean_stored
    );
    $self->ships_travelling->delete;
    $self->simpledb->domain('travel_queue')->search(where=>{foreign_body_id => $self->id})->delete;
    $self->simpledb->domain('spies')->search(where=>{from_body_id => $self->id})->delete;
    foreach my $attribute (@attributes) {
        $self->$attribute(0);
    }
    $self->empire_id('None');
    if ($self->get_type eq 'habitable planet') {
        $self->usable_as_starter(rand(99999));
    }
    $self->put;
}

around 'get_status' => sub {
    my ($orig, $self, $empire) = @_;
    my $out = $orig->($self);
    my %ore;
    foreach my $type (ORE_TYPES) {
        $ore{$type} = $self->$type();
    }
    $out->{size}            = $self->size;
    $out->{ore}             = \%ore;
    $out->{water}           = $self->water;
    if (defined $empire) {
        if ($self->empire_id eq $empire->id) {
            $out->{alignment} = 'self';
        }
        elsif ($self->empire_id ne 'None') {
            $out->{alignment} = 'hostile';
        }
    }
    if (defined $empire && $empire->id eq $self->empire_id) {
        $self->tick;
        $out->{building_count}  = $self->building_count;
        $out->{water_capacity}  = $self->water_capacity;
        $out->{water_stored}    = $self->water_stored;
        $out->{water_hour}      = $self->water_hour;
        $out->{energy_capacity} = $self->energy_capacity;
        $out->{energy_stored}   = $self->energy_stored;
        $out->{energy_hour}     = $self->energy_hour;
        $out->{food_capacity}   = $self->food_capacity;
        $out->{food_stored}     = $self->food_stored;
        $out->{food_hour}       = $self->food_hour;
        $out->{ore_capacity}    = $self->ore_capacity;
        $out->{ore_stored}      = $self->ore_stored;
        $out->{ore_hour}        = $self->ore_hour;
        $out->{waste_capacity}  = $self->waste_capacity;
        $out->{waste_stored}    = $self->waste_stored;
        $out->{waste_hour}      = $self->waste_hour;
        $out->{happiness}       = $self->happiness;
        $out->{happiness_hour}  = $self->happiness_hour;
    }
    return $out;
};

# resource concentrations
use constant rutile => 1;

use constant chromite => 1;

use constant chalcopyrite => 1;

use constant galena => 1;

use constant gold => 1;

use constant uraninite => 1;

use constant bauxite => 1;

use constant goethite => 1;

use constant halite => 1;

use constant gypsum => 1;

use constant trona => 1;

use constant kerogen => 1;

use constant methane => 1;

use constant anthracite => 1;

use constant sulfur => 1;

use constant zircon => 1;

use constant monazite => 1;

use constant fluorite => 1;

use constant beryl => 1;

use constant magnetite => 1;

use constant water => 0;

sub rutile_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->rutile * $self->ore_hour / 10000);
}
 
sub chromite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->chromite * $self->ore_hour / 10000);
}

sub chalcopyrite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->chalcopyrite * $self->ore_hour / 10000);
}

sub galena_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->galena * $self->ore_hour / 10000);
}

sub gold_hour {
    my ($self) = @_;
    return sprintf('%.0f', $self->gold * $self->ore_hour / 10000);
}

sub uraninite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->uraninite * $self->ore_hour / 10000);
}

sub bauxite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->bauxite * $self->ore_hour / 10000);
}

sub goethite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->goethite * $self->ore_hour / 10000);
}

sub halite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->halite * $self->ore_hour / 10000);
}

sub gypsum_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->gypsum * $self->ore_hour / 10000);
}

sub trona_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->trona * $self->ore_hour / 10000);
}

sub kerogen_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->kerogen * $self->ore_hour / 10000);
}

sub methane_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->methane * $self->ore_hour / 10000);
}

sub anthracite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->anthracite * $self->ore_hour / 10000);
}

sub sulfur_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->sulfur * $self->ore_hour / 10000);
}

sub zircon_hour {
    my ($self) = @_;
    return sprintf('%.0f', $self->zircon * $self->ore_hour / 10000);
}

sub monazite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->monazite * $self->ore_hour / 10000);
}

sub fluorite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->fluorite * $self->ore_hour / 10000);
}

sub beryl_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->beryl * $self->ore_hour / 10000);
}

sub magnetite_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->magnetite * $self->ore_hour / 10000);
}

# BUILDINGS

sub get_buildings_of_class {
    my ($self, $class) = @_;
    return $self->simpledb->domain($class)->search(
        where       => {
            body_id => $self->id,
            class   => $class,
            level   => ['>=', 0],
        },
        order_by    => ['level'],
        set         => {
            body    => $self,
            empire  => $self->empire,
        },
    );
}

has command => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get_buildings_of_class('Lacuna::DB::Building::PlanetaryCommand')->next;
    },
);

has network19 => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get_buildings_of_class('Lacuna::DB::Building::Network19')->next;
    },
);

has refinery => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get_buildings_of_class('Lacuna::DB::Building::Ore::Refinery')->next;
    },
);

sub buildings {
    my $self = shift;
    my $buildings = sub {
        my $class = shift;
        return $self->simpledb->domain($class)->search(
		where	=> { body_id => $self->id },
		set	=> { body => $self, empire => $self->empire },
	);
    };
    return (
	$buildings->('Lacuna::DB::Building'),
        $buildings->('Lacuna::DB::Building::Food'),
        $buildings->('Lacuna::DB::Building::Water'),
        $buildings->('Lacuna::DB::Building::Waste'),
        $buildings->('Lacuna::DB::Building::Ore'),
        $buildings->('Lacuna::DB::Building::Energy'),
        $buildings->('Lacuna::DB::Building::Permanent'),
        );
}

sub is_space_free {
    my ($self, $x, $y) = @_;
    my $db = $self->simpledb;
    foreach my $domain (qw(building energy water food waste ore permanent)) {
        my $count = $db->domain($domain)->count(
            where => {
                body_id => $self->id,
                x       => $x,
                y       => $y,
            },
            consistent => 1, # prevents stacking attack
        );
        return 0 if $count > 0;
    }
    return 1;
}

sub check_for_available_build_space {
    my ($self, $x, $y) = @_;
    if ($x > 5 || $x < -5 || $y > 5 || $y < -5) {
        confess [1009, "That's not a valid space for a building.", [$x, $y]];
    }
    if ($self->building_count >= $self->size) {
        confess [1009, "You've already reached the maximum number of buildings for this planet.", $self->size];
    }
    unless ($self->is_space_free($x, $y)) {
        confess [1009, "That space is already occupied.", [$x,$y]]; 
    }
    return 1;
}

sub has_met_building_prereqs {
    my ($self, $building, $cost) = @_;
    $building->check_build_prereqs($self);
    $self->has_resources_to_build($building, $cost);
    $self->has_max_instances_of_building($building);
    $self->has_resources_to_operate($building);
    return 1;
}

sub can_build_building {
    my ($self, $building) = @_;
    $self->check_for_available_build_space($building->x, $building->y);
    $self->tick;
    $self->has_room_in_build_queue;
    $self->has_met_building_prereqs($building);
    return $self;
}

sub has_room_in_build_queue {
    my ($self) = shift;
    my $max = 1;
    my $dev_ministry = $self->simpledb->domain('Lacuna::DB::Building::Development')->search(
        where   => {
            body_id => $self->id,
            class   => 'Lacuna::DB::Building::Development',
        }
        )->next;
    if (defined $dev_ministry) {
        $max += $dev_ministry->level;
    }
    my $count = $self->simpledb->domain('build_queue')->count(where=>{body_id=>$self->id});
    if ($count >= $max) {
        confess [1009, "There's no room left in the build queue.", $max];
    }
    return 1; 
}

use constant operating_resource_names => qw(food_hour energy_hour ore_hour water_hour waste_hour);

has future_operating_resources => (
    is      => 'rw',
    clearer => 'clear_future_operating_resources',
    lazy    => 1,
    default => sub {
        my $self = shift;
        
        # get current
        my %future;
        foreach my $method ($self->operating_resource_names) {
            $future{$method} = $self->$method;
        }
        
        # adjust for what's already in build queue
        my $queued_builds = $self->builds;
        while (my $build = $queued_builds->next) {
            my $building = $build->building;
            my $other = $building->stats_after_upgrade;
            foreach my $method ($self->operating_resource_names) {
                $future{$method} += $other->{$method} - $building->$method;
            }
        }
        return \%future;
    },
);

sub has_resources_to_operate {
    my ($self, $building, $queued_builds) = @_;
    
    # get future
    my $future = $self->future_operating_resources;
    
    # get change for this building
    my $after = $building->stats_after_upgrade;

    # check our ability to sustain ourselves
    foreach my $method ($self->operating_resource_names) {
        my $delta = $after->{$method} - $building->$method;
        # don't allow it if it sucks resources && its sucking more than we're producing
        if ($delta < 0 && $future->{$method} + $delta < 0) {
            my $resource = $method;
            $resource =~ s/(\w+)_hour/$1/;
            confess [1012, "Unsustainable. Not enough resources being produced to build this.", $resource];
        }
    }
    return 1;
}

sub has_resources_to_build {
    my ($self, $building, $cost) = @_;
    $cost ||= $building->cost_to_upgrade;
    foreach my $resource (qw(food energy ore water)) {
        my $stored = $resource.'_stored';
        unless ($self->$stored >= $cost->{$resource}) {
            confess [1011, "Not enough resources in storage to build this.", $resource];
        }
    }
    return 1;
}

sub has_max_instances_of_building {
    my ($self, $building) = @_;
    return 0 if $building->max_instances_per_planet == 9999999;
    my $count = $self->simpledb->domain($building->class)->count(where=>{body_id=>$self->id, class=>$building->class});
    if ($count >= $building->max_instances_per_planet) {
        confess [1009, sprintf("You are only allowed %s of these buildings per planet.",$building->max_instances_per_planet), [$building->max_instances_per_planet, $count]];
    }
}

has last_in_build_queue => (
    is      => 'ro',
    clearer => 'clear_last_in_build_queue',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->builds(undef, 1)->next;
    }
);

sub get_existing_build_queue_time {
    my $self = shift;
    my $time_to_build = DateTime->now;
    my $last_in_queue = $self->last_in_build_queue;
    if (defined $last_in_queue) {
        $time_to_build = $last_in_queue->date_complete;    
    }
    return $time_to_build;
}

sub lock_plot {
    my ($self, $x, $y) = @_;
    return $self->simpledb->cache->set('plot_contention_lock', $self->id.'|'.$x.'|'.$y,{locked=>1}, 30); # lock it
}

sub is_plot_locked {
    my ($self, $x, $y) = @_;
    return eval{$self->simpledb->cache->get('plot_contention_lock', $self->id.'|'.$x.'|'.$y)->{locked}};
}

sub build_building {
    my ($self, $building) = @_;
    
    $self->building_count($self->building_count + 1);
    $self->put;
    
    # set time to build, plus what's in the queue
    my $time_to_build = $self->get_existing_build_queue_time->add(seconds=>$building->time_to_build);
    
    # add to build queue
    my $queue = $self->simpledb->domain('build_queue')->insert({
        date_created        => DateTime->now,
        date_complete       => $time_to_build,
        building_id         => $building->id,
        empire_id           => $self->empire_id,
        building_class      => $building->class,
        body_id             => $self->id,
    });

    # add building placeholder to planet
    $building->build_queue_id($queue->id);
    $building->put;

    $self->empire->trigger_full_update;
}

sub found_colony {
    my ($self, $empire) = @_;
    $self->empire($empire);
    $self->empire_id($empire->id);
    $self->usable_as_starter('No');
    $self->last_tick(DateTime->now);
    $self->put;    

    # award medal
    my $type = ref $self;
    $type =~ s/^.*::(\w\d+)$/$1/;
    $empire->add_medal($type);

    # add command building
    my $command = Lacuna::DB::Building::PlanetaryCommand->new(
        simpledb        => $self->simpledb,
        x               => 0,
        y               => 0,
        class           => 'Lacuna::DB::Building::PlanetaryCommand',
        date_created    => DateTime->now,
        body_id         => $self->id,
        body            => $self,
        empire_id       => $empire->id,
        empire          => $empire,
        level           => $empire->species->growth_affinity - 1,
    );
    $self->build_building($command);
    $command->finish_upgrade;
    
    # add starting resources
    $self->tick;
    $self->add_algae(700);
    $self->add_energy(700);
    $self->add_water(700);
    $self->add_ore(700);
    $self->put;
    
    # newsworthy
    $self->add_news(75,'%s founded a new colony on %s.', $empire->name, $self->name);
        
    return $self;
}

sub recalc_stats {
    my ($self) = @_;
    my %stats = ( needs_recalc => 0 );
    foreach my $buildings ($self->buildings) {
        while (my $building = $buildings->next) {
            $stats{waste_capacity} += $building->waste_capacity;
            $stats{water_capacity} += $building->water_capacity;
            $stats{energy_capacity} += $building->energy_capacity;
            $stats{food_capacity} += $building->food_capacity;
            $stats{ore_capacity} += $building->ore_capacity;
            $stats{happiness_hour} += $building->happiness_hour;
            $stats{waste_hour} += $building->waste_hour;               
            $stats{energy_hour} += $building->energy_hour;
            $stats{water_hour} += $building->water_hour;
            $stats{ore_hour} += $building->ore_hour;
            $stats{food_consumption_hour} += $building->food_consumption_hour;
            foreach my $type (FOOD_TYPES) {
                my $method = $type.'_production_hour';
                $stats{$method} += $building->$method();
            }
         }
    }
    $self->update(\%stats);
    $self->put;
    return $self;
}


sub add_news {
    my $self = shift;
    my $chance = shift;
    my $headline = shift;
    my $network19 = $self->network19;
    if (defined $network19) {
        $chance += $network19->level * 2;
        if ($network19->restrict_coverage) {
            $chance = $chance / $self->command->level; 
        }
    }
    if (randint(1,100) <= $chance) {
        $headline = sprintf $headline, @_;
        Lacuna::DB::News->new(
            simpledb    => $self->simpledb,
            date_posted => DateTime->now,
            zone        => $self->zone,
            headline    => $headline,
        )->put;
        return 1;
    }
    return 0;
}


# RESOURCE MANGEMENT

sub tick {
    my ($self) = @_;
    my $now = DateTime->now;
    my $builds = $self->builds({date_complete => ['<=', $now]});
    my $ships_travelling = $self->ships_travelling({date_arrives => ['<=', $now]});
    my $ship = $ships_travelling->next;
    my $build = $builds->next;
    
    # deal with events that may have occurred
    while (1) {
        if (defined $ship && defined $build ) {
            if ( $ship->date_arrives > $build->date_complete ) {
                $self->tick_to($build->date_complete);
                $build->finish_build;
                $build = $builds->next;
            }
            else {
                $self->tick_to($ship->date_arrives);
                $ship->arrive;
                $ship = $ships_travelling->next; 
            }
        }
        elsif (defined $build) {
            $self->tick_to($build->date_complete);
            $build->finish_build;
            $build = $builds->next;
        }
        elsif (defined $ship) {
            $self->tick_to($ship->date_arrives);
            $ship->arrive;
            $ship = $ships_travelling->next; 
        }
        else {
            last;
        }
    }

    # check / clear boosts
    if ($self->boost_enabled) {
        my $empire = $self->empire;
        my $still_enabled = 0;
        foreach my $resource (qw(energy water ore happiness food)) {
            my $boost = $resource.'_boost';
            if ($now > $empire->$boost) {
                $self->needs_recalc(1);
            }
            else {
                $still_enabled = 1;
            }
        }
        unless ($still_enabled) {
            $self->boost_enabled(0);
        }
    }

    $self->tick_to($now);

    # clear caches
    $self->clear_future_operating_resources;
    
}

sub tick_to {
    my ($self, $now) = @_;
    my $interval = $now - $self->last_tick;
    my $seconds = to_seconds($interval);
    my $tick_rate = $seconds / 3600;
    $self->last_tick($now);
    if ($self->needs_recalc) {
        $self->recalc_stats;    
    }
    $self->add_happiness(sprintf('%.0f', $self->happiness_hour * $tick_rate));
    $self->add_waste(sprintf('%.0f', $self->waste_hour * $tick_rate));
    $self->add_energy(sprintf('%.0f', $self->energy_hour * $tick_rate));
    $self->add_water(sprintf('%.0f', $self->water_hour * $tick_rate));
    foreach my $type (ORE_TYPES) {
        my $hour_method = $type.'_hour';
        my $add_method = 'add_'.$type;
        $self->$add_method(sprintf('%.0f', $self->$hour_method() * $tick_rate));
    }
    my $food_consumed = sprintf('%.0f', $self->food_consumption_hour * $tick_rate);
    foreach my $type (shuffle FOOD_TYPES) {
        my $hour_method = $type.'_production_hour';
        my $add_method = 'add_'.$type;
        my $food_produced = sprintf('%.0f', $self->$hour_method() * $tick_rate);
        if ($food_produced > $food_consumed) {
            $food_produced -= $food_consumed;
            $food_consumed = 0;
            $self->$add_method($food_produced);
        }
        else {
            $food_consumed -= $food_produced;
        }
    }
    $self->put;
}

sub food_hour {
    my ($self) = @_;
    my $tally = 0;
    foreach my $food (FOOD_TYPES) {
        my $method = $food."_production_hour";
        $tally += $self->$method;
    }
    $tally -= $self->food_consumption_hour;
    return $tally;
}

sub food_stored {
    my ($self) = @_;
    my $tally = 0;
    foreach my $food (FOOD_TYPES) {
        my $method = $food."_stored";
        $tally += $self->$method;
    }
    return $tally;
}

sub ore_stored {
    my ($self) = @_;
    my $tally = 0;
    foreach my $ore (ORE_TYPES) {
        my $method = $ore."_stored";
        $tally += $self->$method;
    }
    return $tally;
}

sub add_ore {
    my ($self, $value) = @_;
    foreach my $type (shuffle ORE_TYPES) {
        next unless $self->$type >= 100; 
        my $add_method = 'add_'.$type;
        $self->$add_method($value);
        last;
    }
}

sub add_magnetite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->magnetite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->magnetite_stored;
    $self->magnetite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_beryl {
    my ($self, $value) = @_;
    my $amount_to_store = $self->beryl_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->beryl_stored;
    $self->beryl_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_fluorite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->fluorite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->fluorite_stored;
    $self->fluorite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_monazite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->monazite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->monazite_stored;
    $self->monazite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_zircon {
    my ($self, $value) = @_;
    my $amount_to_store = $self->zircon_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->zircon_stored;
    $self->zircon_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_sulfur {
    my ($self, $value) = @_;
    my $amount_to_store = $self->sulfur_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->sulfur_stored;
    $self->sulfur_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_anthracite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->anthracite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->anthracite_stored;
    $self->anthracite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_methane {
    my ($self, $value) = @_;
    my $amount_to_store = $self->methane_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->methane_stored;
    $self->methane_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_kerogen {
    my ($self, $value) = @_;
    my $amount_to_store = $self->kerogen_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->kerogen_stored;
    $self->kerogen_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_trona {
    my ($self, $value) = @_;
    my $amount_to_store = $self->trona_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->trona_stored;
    $self->trona_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_gypsum {
    my ($self, $value) = @_;
    my $amount_to_store = $self->gypsum_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->gypsum_stored;
    $self->gypsum_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_halite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->halite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->halite_stored;
    $self->halite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_goethite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->goethite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->goethite_stored;
    $self->goethite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_bauxite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->bauxite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->bauxite_stored;
    $self->bauxite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_uraninite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->uraninite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->uraninite_stored;
    $self->uraninite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_gold {
    my ($self, $value) = @_;
    my $amount_to_store = $self->gold_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->gold_stored;
    $self->gold_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_galena {
    my ($self, $value) = @_;
    my $amount_to_store = $self->galena_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->galena_stored;
    $self->galena_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_chalcopyrite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->chalcopyrite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->chalcopyrite_stored;
    $self->chalcopyrite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_chromite {
    my ($self, $value) = @_;
    my $amount_to_store = $self->chromite_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->chromite_stored;
    $self->chromite_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_rutile {
    my ($self, $value) = @_;
    my $amount_to_store = $self->rutile_stored + $value;
    my $available_storage = $self->ore_capacity - $self->ore_stored + $self->rutile_stored;
    $self->rutile_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub spend_ore {
    my ($self, $value) = @_;
    my $subtract = sprintf('%.0f', $value / 5);
    SPEND: while (1) {
        foreach my $type (shuffle ORE_TYPES) {
            my $method = $type."_stored";
            my $stored = $self->$method;
            if ($stored > $subtract) {
                $self->$method($stored - $subtract);
                $value -= $subtract;
            }
            else {
                $value -= $stored;
                $self->$method(0);
            }
            last SPEND if ($value <= 0);
            $subtract = $value if ($subtract > $value);
        }
        last SPEND if ($subtract <= 0); # prevent an infinite loop scenario
    }
    return $self;
}

sub add_beetle {
    my ($self, $value) = @_;
    my $amount_to_store = $self->beetle_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->beetle_stored;
    $self->beetle_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_shake {
    my ($self, $value) = @_;
    my $amount_to_store = $self->shake_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->shake_stored;
    $self->shake_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_burger {
    my ($self, $value) = @_;
    my $amount_to_store = $self->burger_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->burger_stored;
    $self->burger_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_fungus {
    my ($self, $value) = @_;
    my $amount_to_store = $self->fungus_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->fungus_stored;
    $self->fungus_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_syrup {
    my ($self, $value) = @_;
    my $amount_to_store = $self->syrup_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->syrup_stored;
    $self->syrup_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_algae {
    my ($self, $value) = @_;
    my $amount_to_store = $self->algae_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->algae_stored;
    $self->algae_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_meal {
    my ($self, $value) = @_;
    my $amount_to_store = $self->meal_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->meal_stored;
    $self->meal_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_milk {
    my ($self, $value) = @_;
    my $amount_to_store = $self->milk_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->milk_stored;
    $self->milk_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_pancake {
    my ($self, $value) = @_;
    my $amount_to_store = $self->pancake_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->pancake_stored;
    $self->pancake_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_pie {
    my ($self, $value) = @_;
    my $amount_to_store = $self->pie_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->pie_stored;
    $self->pie_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_chip {
    my ($self, $value) = @_;
    my $amount_to_store = $self->chip_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->chip_stored;
    $self->chip_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_soup {
    my ($self, $value) = @_;
    my $amount_to_store = $self->soup_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->soup_stored;
    $self->soup_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_bread {
    my ($self, $value) = @_;
    my $amount_to_store = $self->bread_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->bread_stored;
    $self->bread_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_wheat {
    my ($self, $value) = @_;
    my $amount_to_store = $self->wheat_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->wheat_stored;
    $self->wheat_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_cider {
    my ($self, $value) = @_;
    my $amount_to_store = $self->cider_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->cider_stored;
    $self->cider_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_corn {
    my ($self, $value) = @_;
    my $amount_to_store = $self->corn_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->corn_stored;
    $self->corn_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_root {
    my ($self, $value) = @_;
    my $amount_to_store = $self->root_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->root_stored;
    $self->root_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_bean {
    my ($self, $value) = @_;
    my $amount_to_store = $self->bean_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->bean_stored;
    $self->bean_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_apple {
    my ($self, $value) = @_;
    my $amount_to_store = $self->apple_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->apple_stored;
    $self->apple_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_potato {
    my ($self, $value) = @_;
    my $amount_to_store = $self->potato_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->potato_stored;
    $self->potato_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub add_lapis {
    my ($self, $value) = @_;
    my $amount_to_store = $self->lapis_stored + $value;
    my $available_storage = $self->food_capacity - $self->food_stored + $self->lapis_stored;
    $self->lapis_stored( ($amount_to_store < $available_storage) ? $amount_to_store : $available_storage );
}

sub spend_food {
    my ($self, $value) = @_;
    my $subtract = sprintf('%.0f', $value / 5);
    SPEND: while (1) {
        foreach my $type (shuffle FOOD_TYPES) {
            my $method = $type."_stored";
            my $stored = $self->$method;
            if ($stored > $subtract) {
                $self->$method($stored - $subtract);
                $value -= $subtract;
            }
            else {
                $value -= $stored;
                $self->$method(0);
            }
            last SPEND if ($value <= 0);
            $subtract = $value if ($subtract > $value);
        }
        last SPEND if ($subtract <= 0); # prevent an infinite loop scenario
    }
    return $self;
}

sub add_energy {
    my ($self, $value) = @_;
    my $store = $self->energy_stored + $value;
    my $storage = $self->energy_capacity;
    $self->energy_stored( ($store < $storage) ? $store : $storage );
}

sub spend_energy {
    my ($self, $value) = @_;
    $self->energy_stored( $self->energy_stored - $value );
}

sub add_water {
    my ($self, $value) = @_;
    my $store = $self->water_stored + $value;
    my $storage = $self->water_capacity;
    $self->water_stored( ($store < $storage) ? $store : $storage );
}

sub spend_water {
    my ($self, $value) = @_;
    $self->water_stored( $self->water_stored - $value );
}

sub add_happiness {
    my ($self, $value) = @_;
    my $new = $self->happiness + $value;
    if ($new < 0 && $self->empire->is_isolationist) {
        $new = 0;
    }
    $self->happiness( $new );
}

sub spend_happiness {
    my ($self, $value) = @_;
    my $new = $self->happiness - $value;
    if ($new < 0 && $self->empire->is_isolationist) {
        $new = 0;
    }
    $self->happiness( $new );
}

sub add_waste {
    my ($self, $value) = @_;
    my $store = $self->waste_stored + $value;
    my $storage = $self->waste_capacity;
    if ($store < $storage) {
        $self->waste_stored( $store );
    }
    else {
        $self->waste_stored( $storage );
        $self->spend_happiness( $store - $storage ); # pollution
    }
}

sub spend_waste {
    my ($self, $value) = @_;
    $self->waste_stored( $self->waste_stored - $value );
}


no Moose;
__PACKAGE__->meta->make_immutable;
