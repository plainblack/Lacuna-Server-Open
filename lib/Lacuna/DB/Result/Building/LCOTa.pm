package Lacuna::DB::Result::Building::LCOTa;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(GROWTH);
with 'Lacuna::Role::LCOT';

use constant controller_class => 'Lacuna::RPC::Building::LCOTa';
use constant image => 'lcota';
use constant name => 'Lost City of Tyleon (A)';
use constant energy_storage => 10000;
use constant water_storage => 10000;
use constant food_storage => 10000;
use constant ore_storage => 10000;
use constant waste_storage => 1000;
use constant waste_consumption => 450;
use constant happiness_production => 2250;
use constant energy_production => 2250;
use constant water_production => 2250;
use constant ore_production => 2250;
use constant burger_production => 375;
use constant chip_production => 375;
use constant pie_production => 375;
use constant shake_production => 375;
use constant soup_production => 375;
use constant syrup_production => 375;
around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(burger chip pie shake soup syrup);
    return $foods;
};

has effective_efficiency => (
    is          => 'rw',
    lazy        => 1,
    predicate   => 'has_effective_efficiency',
    default     => 0,
);

has effective_level => (
    is      => 'rw',
    lazy        => 1,
    predicate   => 'has_effective_level',
    default     => 0,
);

sub production_hour {
    my $self = shift;
    return 0 unless  $self->level;
    unless ($self->has_effective_level) {
        $self->calculate_effective_stats;
    }
    my $production = (GROWTH ** (  $self->effective_level - 1));
    $production = ($production * $self->effective_efficiency) / 100;
    return $production;
}


sub stats_after_upgrade {
    my ($self) = @_;
    my $current_level = $self->level;
    unless ($self->has_effective_level) {
        $self->calculate_effective_stats;
    }
    $self->level($self->effective_level + 2);
    my %stats;
    my @list = qw(food_hour food_capacity ore_hour ore_capacity water_hour water_capacity waste_hour waste_capacity energy_hour energy_capacity happiness_hour);
    foreach my $resource (@list) {
        $stats{$resource} = $self->$resource;
    }
    $self->level($current_level);
    return \%stats;
}

sub calculate_effective_stats {
    my $self = shift;
    my $level = $self->level;
    my $efficiency = $self->efficiency;
    my $body = $self->body;
    foreach my $ext (qw(b c d e f g h i)) {
        my $part = $body->get_building_of_class('Lacuna::DB::Result::Building::LCOT'.$ext);
        if (defined $part) {
            $level = $part->level < $level ? $part->level : $level;
            $efficiency = $part->efficiency < $efficiency ? $part->efficiency : $efficiency;
        }
        else {
            $level = 0;
            $efficiency = 0;
        }
        last if $level < 1 || $efficiency < 1;
    }
    $self->effective_level($level);
    $self->effective_efficiency($efficiency);
}


before 'can_demolish' => sub {
    my $self = shift;
    my $b = $self->body->get_building_of_class('Lacuna::DB::Result::Building::LCOTb');
    if (defined $b) {
        confess [1013, 'You have to demolish your Lost City of Tyleon (B) before you can demolish your Lost City of Tyleon (A).'];
    }
};

before can_build => sub {
    my $self = shift;
    if ($self->x ~~ [-5,5] || $self->y ~~ [-5,5] || ($self->x ~~ [-1,0,1] && $self->y ~~ [-1,0,1] )) {
        confess [1009, 'Lost City of Tyleon cannot be placed in that location.'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
