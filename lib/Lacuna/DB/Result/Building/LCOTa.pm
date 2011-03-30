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
use constant energy_storage => 21000;
use constant water_storage => 21000;
use constant food_storage => 21000;
use constant ore_storage => 21000;
use constant waste_storage => 7000;
use constant waste_consumption => 700;
use constant happiness_production => 6300;
use constant energy_production => 6300;
use constant water_production => 6300;
use constant ore_production => 6300;
use constant burger_production => 6300;
use constant chip_production => 1100;
use constant pie_production => 1100;
use constant shake_production => 1100;
use constant soup_production => 1100;
use constant syrup_production => 1100;
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
);

has effective_level => (
    is      => 'rw',
    lazy        => 1,
    predicate   => 'has_effective_efficiency',
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
    if ($self->x ~~ [-5,-1,0,1,5] || $self->y ~~ [-5,-1,0,1,5]) {
        confess [1009, 'Lost City of Tyleon cannot be placed in that location.'];
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
