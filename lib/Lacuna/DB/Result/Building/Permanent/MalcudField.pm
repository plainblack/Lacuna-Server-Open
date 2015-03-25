package Lacuna::DB::Result::Building::Permanent::MalcudField;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::UpgradeWithHalls";
with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::MalcudField';

use constant image => 'malcudfield';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, 'Today the governor of %s announced that a wild malcud field would be set aside as a nature preserve.', $self->body->name);
};

use constant name => 'Malcud Field';
use constant fungus_production => 4000;
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(fungus);
    return $foods;
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
