package Lacuna::DB::Result::Building::Permanent::MassadsHenge;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';
use Lacuna::Util qw(randint);

#with "Lacuna::Role::Building::UpgradeWithHalls";
#with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::MassadsHenge';

# When enabled, delete the following around can_build and can_upgrade
# TODO
around can_build => sub {
    my ($orig, $self, $body) = @_;
    confess [1013,"You can't build Massad's Henge."];
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build Massad's Henge."];
};

around can_upgrade => sub {
    my ($orig, $self) = @_;
    confess [1013,"You can't upgrade Massad's Henge. It was left behind by the Great Race."];
    if ($self->body->get_plan(__PACKAGE__, $self->level + 1)) {
        return $orig->($self);  
    }
    confess [1013,"You can't upgrade Massad's Henge. It was left behind by the Great Race."];
};

use constant image => 'massadshenge';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, 'The whole of the heavens are exposed to the citizens of %s.', $self->body->name);
};

use constant name => 'Massad\'s Henge';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
