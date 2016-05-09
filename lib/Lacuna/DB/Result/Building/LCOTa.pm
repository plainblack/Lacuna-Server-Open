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
use constant energy_storage => 2000;
use constant water_storage => 2000;
use constant food_storage => 2000;
use constant ore_storage => 2000;
use constant waste_storage => 2000;
use constant waste_production  => 0;
use constant waste_consumption => 400;
use constant happiness_production => 1000;
use constant energy_production => 1200;
use constant water_production => 1200;
use constant ore_production => 1200;
use constant burger_production => 250;
use constant chip_production => 250;
use constant pie_production => 250;
use constant shake_production => 250;
use constant soup_production => 250;
use constant syrup_production => 250;
around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(burger chip pie shake soup syrup);
    return $foods;
};

has '+effective_level' => (
    predicate   => 'has_effective_level',
);

around '_build_effective_level' => sub {
    my ($orig, $self) = @_;
    my $level = $self->$orig;
    my $body = $self->body;
    foreach my $ext (qw(b c d e f g h i)) {
        my $part = $body->get_building_of_class('Lacuna::DB::Result::Building::LCOT'.$ext);
        if (defined $part) {
            $level = $part->effective_level < $level ? $part->effective_level : $level;
        }
        else {
            $level = 0;
        }
        last if $level < 1;
    }
    return $level;
};

around '_build_effective_efficiency' => sub {
    my ($orig, $self) = @_;
    my $efficiency = $self->$orig;
    my $body = $self->body;
    foreach my $ext (qw(b c d e f g h i)) {
        my $part = $body->get_building_of_class('Lacuna::DB::Result::Building::LCOT'.$ext);
        if (defined $part) {
            $efficiency = $part->effective_efficiency < $efficiency ? $part->effective_efficiency : $efficiency;
        }
        else {
            $efficiency = 0;
        }
        last if $efficiency < 1;
    }
    return $efficiency;
};

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
