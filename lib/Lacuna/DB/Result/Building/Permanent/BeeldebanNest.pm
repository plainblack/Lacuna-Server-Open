package Lacuna::DB::Result::Building::Permanent::BeeldebanNest;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';
use Lacuna::Util qw(random_element);

use constant controller_class => 'Lacuna::RPC::Building::BeeldebanNest';

with "Lacuna::Role::Building::UpgradeWithHalls";
with "Lacuna::Role::Building::FormsNaturally";

use constant image => 'beeldebannest';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

my @upgrades = (
                'A boy was nearly killed today when he and his sister wandered into a wild Beeldeban nest on %s today.',
                'A girl was nearly killed today when she and her brother wandered into a wild Beeldeban nest on %s today.',
               );

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, random_element(\@upgrades), $self->body->name);
};

use constant name => 'Beeldeban Nest';
use constant min_orbit => 5;
use constant max_orbit => 6;
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;
use constant beetle_production => 4000;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(beetle);
    return $foods;
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
