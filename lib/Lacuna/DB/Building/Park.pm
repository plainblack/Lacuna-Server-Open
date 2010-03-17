package Lacuna::DB::Building::Park;

use Moose;
extends 'Lacuna::DB::Building';
use DateTime;
use Lacuna::Constants qw(FOOD_TYPES);
use Lacuna::Util qw(to_seconds);

__PACKAGE__->add_attributes(
    party_ends              => { isa => 'DateTime' },
    party_in_progress       => { isa => 'Str', default => 0 },
    happiness_from_party    => { isa => 'Int', default => 0 },
);

sub party_seconds_remaining {
    my ($self) = @_;
    return to_seconds($self->party_ends - DateTime->now);
}

sub can_throw_a_party {
    my ($self) = @_;
    if ($self->level < 1) {
        confess [1010, "You can't throw a party until the park is built."];
    }
    if ($self->party_in_progress) {
        confess [1010, "There is already a party in progress."];
    }
    unless ($self->body->food_stored >= 10_000) {
        confess [1011, "Insufficient food to throw a party."];
    }
    return 1;
}

sub throw_a_party {
    my ($self) = @_;
    $self->can_throw_a_party;
    
    my $body = $self->body;
    my $eat = 10_000;
    my $food_multiplier = 0;
    foreach my $food (FOOD_TYPES) {
        my $food_stored = $food.'_stored';
        if ($body->$food_stored >= 500) {
            $food_multiplier++;
            $body->$food_stored( $body->$food_stored() - 500 );
        }
    }
    if ($eat) { # leftovers
        $body->spend_food($eat);
    }
    $body->put;
    
    $self->party_ends(DateTime->now->add(days=>1));
    $self->party_in_progress(1);
    $self->happiness_from_party(3_000 * $food_multiplier * $self->happiness_production_bonus);
    $self->put;
}

sub end_the_party {
    my ($self) = @_;
    $self->party_in_progress(0);
    $self->put;
    my $planet = $self->body;
    $planet->add_happiness($self->happiness_from_party);
    $planet->put;
}

sub check_party_over {
    my ($self) = @_;
    if ($self->party_in_progress) {
        if ($self->party_ends < DateTime->now) {
            $self->end_the_party;
        }
    }
}

use constant controller_class => 'Lacuna::Building::Park';

use constant building_prereq => {'Lacuna::DB::Building::PlanetaryCommand'=>5};

use constant image => 'park';

use constant name => 'Park';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 100;

use constant water_to_build => 100;

use constant waste_to_build => 100;

use constant time_to_build => 500;

use constant food_consumption => 10;

use constant energy_consumption => 10;

use constant ore_consumption => 20;

use constant water_consumption => 60;

use constant waste_production => 75;

use constant happiness_production => 75;



no Moose;
__PACKAGE__->meta->make_immutable;
