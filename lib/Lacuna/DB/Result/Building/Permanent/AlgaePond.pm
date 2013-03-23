package Lacuna::DB::Result::Building::Permanent::AlgaePond;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';
use Lacuna::Util qw(randint);

use constant controller_class => 'Lacuna::RPC::Building::AlgaePond';

with "Lacuna::Role::Building::UpgradeWithHalls";
with "Lacuna::Role::Building::FormsNaturally";

use constant image => 'algaepond';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('This is no fisherman\'s tale. A local fisherman caught a '.randint(1,9).' meter Rakl out of an algae pond on %s.', $self->body->name));
};

use constant name                       => 'Algae Pond';
use constant time_to_build              => 0;
use constant max_instances_per_planet   => 1;
use constant algae_production           => 4000; 

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(algae);
    return $foods;
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
