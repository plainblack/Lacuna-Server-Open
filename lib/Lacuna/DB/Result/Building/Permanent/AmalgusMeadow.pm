package Lacuna::DB::Result::Building::Permanent::AmalgusMeadow;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::AmalgusMeadow';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build an Amalgus Meadow. It forms naturally."];
};

around can_upgrade => sub {
    my ($orig, $self) = @_;
    if ($self->body->get_plan(__PACKAGE__, $self->level + 1)) {
        return $orig->($self);  
    }
    confess [1013,"You can't upgrade an Amalgus Meadow. It forms naturally."];
};

use constant image => 'amalgusmeadow';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('Children everywhere on %s where heard singing "Beans, beans, the music fruit" after they discovered an Amalgus Meadow today.', $self->body->name));
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
