package Lacuna::DB::Result::Building::Park;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use DateTime;
use Lacuna::Constants qw(FOOD_TYPES);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness));
};


sub can_throw_a_party {
    my ($self) = @_;
    if ($self->effective_level < 1) {
        confess [1010, "You can't throw a party until the park is built."];
    }
    if ($self->is_working) {
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
    my $food_multiplier = $self->effective_level * 0.3;
    foreach my $food (FOOD_TYPES) {
        if ($body->type_stored($food) >= 500) {
            $food_multiplier++;
            $body->spend_food_type($food, 500, 0);
            $eat -= 500;
        }
    }
    if ($eat) { # leftovers
        $body->spend_food($eat);
    }
    $body->update;
    
    $self->start_work({
        happiness_from_party    => sprintf('%.0f', 3_000 * $food_multiplier * $self->happiness_production_bonus),
        }, 60*60*12)->update;
}

before finish_work => sub {
    my $self = shift;
    my $planet = $self->body;
    $planet->add_happiness($self->work->{happiness_from_party})->update;
};

use constant controller_class => 'Lacuna::RPC::Building::Park';

use constant university_prereq => 4;

use constant image => 'park';

use constant name => 'Park';

use constant food_to_build => 20;

use constant energy_to_build => 20;

use constant ore_to_build => 20;

use constant water_to_build => 20;

use constant waste_to_build => 10;

use constant time_to_build => 85;

use constant food_consumption => 1;

use constant energy_consumption => 1;

use constant ore_consumption => 1;

use constant water_consumption => 4;

use constant waste_production => 3;

use constant happiness_production => 4;



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
