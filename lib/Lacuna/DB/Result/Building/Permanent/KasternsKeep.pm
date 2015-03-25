package Lacuna::DB::Result::Building::Permanent::KasternsKeep;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';
use Lacuna::Util qw(randint);

#with "Lacuna::Role::Building::UpgradeWithHalls";
#with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::KasternsKeep';

# delete the around can_build and can_upgrade when we enable the Keep
# TODO
around can_build => sub {
    my ($orig, $self, $body) = @_;
    confess [1013,"You can't build Kastern's Keep."];
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build Kastern's Keep."];
};

around can_upgrade => sub {
    my ($orig, $self) = @_;
    confess [1013,"You can't upgrade Kastern's Keep. It was left behind by the Great Race."];
    if ($self->body->get_plan(__PACKAGE__, $self->level + 1)) {
        return $orig->($self);  
    }
    confess [1013,"You can't upgrade Kastern's Keep. It was left behind by the Great Race."];
};

use constant image => 'kasternskeep';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, 'The old castle stands alone atop a bluff on %s. And still looks majestic after all these years.', $self->body->name);
};

use constant name => 'Kastern\'s Keep';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
