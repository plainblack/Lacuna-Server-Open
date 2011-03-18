package Lacuna::DB::Result::Building::Permanent::DentonBrambles;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::DentonBrambles';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build Denton Brambles. They form naturally."];
};

around can_upgrade => sub {
    my ($orig, $self) = @_;
    if ($self->body->get_plan(__PACKAGE__, $self->level + 1)) {
        return $orig->($self);  
    }
    confess [1013,"You can't upgrade Denton Brambles. They form naturally."];
};

use constant image => 'dentonbrambles';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('Tender and juicy denton roots await those souls of %s who are brave enough to tackle the Denton Brambles.', $self->body->name));
};

use constant min_orbit => 5;
use constant max_orbit => 6;
use constant name => 'Denton Brambles';
use constant bean_production => 4000;
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(root);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
