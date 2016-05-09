package Lacuna::DB::Result::Building::Permanent::Lake;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::Lake';

sub can_upgrade {
    confess [1013, "You can't upgrade a lake. It forms naturally."];
}

use constant image => 'lake';
use constant algae_production => 20; 
around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(algae);
    return $foods;
};
use constant water_production => 20;

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Lake';

use constant time_to_build => 0;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
