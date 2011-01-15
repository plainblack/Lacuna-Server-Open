package Lacuna::DB::Result::Building::Permanent::LapisForest;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::LapisForest';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build a Lapis Forest. It forms naturally."];
};

around can_upgrade => sub {
    my ($orig, $self) = @_;
    if ($self->body->get_plan(__PACKAGE__, $self->level + 1)) {
        return $orig->($self);  
    }
    confess [1013,"You can't upgrade a Lapis Forest. It forms naturally."];
};

use constant image => 'lapisforest';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(40, sprintf('The poet known for his "Ode To A Lapis Forest" is scheduled to speak today on %s.', $self->body->name));
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
