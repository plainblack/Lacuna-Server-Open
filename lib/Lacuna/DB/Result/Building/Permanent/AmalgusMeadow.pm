package Lacuna::DB::Result::Building::Permanent::AmalgusMeadow;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::UpgradeWithHalls";
with "Lacuna::Role::Building::FormsNaturally";

use constant controller_class => 'Lacuna::RPC::Building::AmalgusMeadow';

use constant image => 'amalgusmeadow';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, 'Children everywhere on %s were heard singing "Beans, beans, the music fruit" after they discovered an Amalgus Meadow today.', $self->body->name);
};

use constant min_orbit => 4;
use constant max_orbit => 4;
use constant name => 'Amalgus Meadow';
use constant bean_production => 4000;
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(bean);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
