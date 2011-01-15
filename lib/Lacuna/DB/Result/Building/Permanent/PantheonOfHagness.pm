package Lacuna::DB::Result::Building::Permanent::PantheonOfHagness;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::PantheonOfHagness';
use Lacuna::Util qw(randint);

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build the Pantheon Of Hagness. It was left behind by the Great Race."];
};

around can_upgrade => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, $self->level + 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't upgrade the Pantheon Of Hagness. It was left behind by the Great Race."];
};

use constant image => 'pantheonofhagness';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(50, sprintf('No one is certain how, but measurements of %s from the ground indicate it\'s bigger than measurements from space.', $self->body->name));
};

use constant name => 'Pantheon of Hagness';

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
