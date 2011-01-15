package Lacuna::DB::Result::Building::Permanent::Volcano;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::Volcano';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build a Volcano. It forms naturally."];
};

around can_upgrade => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, $self->level + 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't upgrade a Volcano. It forms naturally."];
};


use constant image => 'volcano';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('A volcano erupted on %s today spewing tons of ash on the inhabitants.', $self->body->name));
};

use constant name => 'Volcano';
use constant ore_production => 4000;

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
