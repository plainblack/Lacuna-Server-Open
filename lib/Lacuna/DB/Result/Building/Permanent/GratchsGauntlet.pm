package Lacuna::DB::Result::Building::Permanent::GratchsGauntlet;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';
use Lacuna::Util qw(randint);

use constant controller_class => 'Lacuna::RPC::Building::GratchsGauntlet';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build Gratch's Gauntlet."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade an Gratch's Gauntlet."];
}

use constant image => 'gratchsgauntlet';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('The agents on %s use techniques handed down for millenia, which they say makes them unbeatable.', $self->body->name));
};

use constant name => 'Gratch\'s Gauntlet';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
