package Lacuna::DB::Result::Building::Permanent::KalavianRuins;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::KalavianRuins';
use Lacuna::Util qw(randint);

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build the Kalavian Ruins. They were left behind by the Great Race."];
};

around can_upgrade => sub {
    my ($orig, $self) = @_;
    if ($self->body->get_plan(__PACKAGE__, $self->level + 1)) {
        return $orig->($self);  
    }
    confess [1013,"You can't upgrade the Kalavian Ruins. It was left behind by the Great Race."];
};

use constant image => 'kalavianruins';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(50, sprintf('Archaeologists estimate that the Kalavian Ruins they uncovered on %s were buried for '.randint(10,99).',000 years.', $self->body->name));
};

use constant name => 'Kalavian Ruins';

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;
use constant happiness_production => 4000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
