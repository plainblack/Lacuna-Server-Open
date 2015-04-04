package Lacuna::DB::Result::Building::Permanent::Fissure;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::Fissure';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build a Fissure. It is created by a violent release of energy."];
};

around can_upgrade => sub {
    my ($orig, $self) = @_;
    if ($self->body->get_plan(__PACKAGE__, $self->level + 1)) {
        return $orig->($self);  
    }
    confess [1013,"You can't upgrade a Fissure. It is expanded by a violent release of energy."];
};

use constant image => 'fissure';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, 'Scientists are worried that %s may collapse in on itself.', $self->body->name);
};

before 'can_demolish' => sub {
    my $self = shift;
    unless ($self->efficiency >= 100) {
        confess [1013, 'Unless your Fissure maintenance equipment is 100% operational, it is just too dangerous to attempt'];
    }
    if ($self->level > 1) {
        confess [1013, 'You must fill in the fissure by spending resources to downgrade it before you can demolish it.'];
    }
};

before 'can_downgrade' => sub {
    my $self = shift;

    unless ($self->efficiency >= 100) {
        confess [1013, 'Unless your Fissure maintenance equipment is 100% operational, it is just too dangerous to attempt.'];
    }
    unless ($self->has_resources_to_fill_in_fissure) {
        confess [1013, 'You need '.int($self->cost_to_fill_in_fissure).' in ore to fill in the fissure.'];
    }
};

before downgrade => sub {
    my $self = shift;
    my $body = $self->body;
    my $cost = $self->cost_to_fill_in_fissure;
    my $stored = $body->ore_stored;
    if ($stored >= $cost) {
        $body->spend_ore($cost);
    }
    else {
        $body->spend_ore($stored);
    }
    $self->body->add_news(30, 'Scientists on %s successfully downgraded a Fissure today.', $self->body->name);
};

sub get_repair_costs {
    my $self = shift;
    my $level_cost = $self->current_level_cost;
    my $damage = 100 - $self->efficiency;
    my $damage_cost = $level_cost * $damage / 100;
    return {
        ore     => sprintf('%.0f', 150 * $damage_cost),
        water   => sprintf('%.0f',  50 * $damage_cost),
        food    => sprintf('%.0f',   0 * $damage_cost),
        energy  => sprintf('%.0f', 100 * $damage_cost),
    };
}

sub cost_to_fill_in_fissure {
    my $self = shift;
    return int($self->current_level_cost * 1350);
}

sub has_resources_to_fill_in_fissure {
    my $self = shift;
    my $body = $self->body;
    my $available = $body->ore_stored;
    return ($self->cost_to_fill_in_fissure <= $available) ? 1 : 0;
}

use constant name => 'Fissure';
use constant time_to_build => 0;
use constant food_to_build => 0;
use constant energy_to_build => 0;
use constant ore_to_build => 0;
use constant water_to_build => 0;
use constant waste_to_build => 0;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
