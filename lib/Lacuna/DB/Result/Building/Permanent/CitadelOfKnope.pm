package Lacuna::DB::Result::Building::Permanent::CitadelOfKnope;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::CitadelOfKnope';
use Lacuna::Util qw(randint);

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build the Citadel of Knope. It was left behind by the Great Race."];
};

around can_upgrade => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, $self->level + 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't upgrade the Citadel of Knope. It was left behind by the Great Race."];
};

use constant image => 'citadelofknope';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(50, sprintf('Research students say that the Citadel of Knope, which remained dormant for years on %s, sprang to life.', $self->body->name));
};

use constant name => 'Citadel of Knope';

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
