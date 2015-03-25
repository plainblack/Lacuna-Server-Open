package Lacuna::DB::Result::Building::Permanent::LapisForest;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::UpgradeWithHalls";
with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::LapisForest';

use constant image => 'lapisforest';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(40, 'The poet known for his "Ode To A Lapis Forest" is scheduled to speak today on %s.', $self->body->name);
};

use constant name => 'Lapis Forest';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;
use constant min_orbit => 2;
use constant max_orbit => 2;
use constant lapis_production => 4000; 

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(lapis);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
