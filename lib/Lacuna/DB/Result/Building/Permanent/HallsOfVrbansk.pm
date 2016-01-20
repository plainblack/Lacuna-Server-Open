package Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk;

use Moose;
use utf8;
use List::Util qw(min);

no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::HallsOfVrbansk';
use constant can_really_be_built => 0;

around can_build => sub {
    confess [1013,"You can't build the Halls of Vrbansk."];
};

around can_upgrade => sub {
    confess [1013,"You can't upgrade the Halls of Vrbansk."];
};

around can_downgrade => sub {
    confess [1013,"You can't downgrade the Halls of Vrbansk."];
};

around can_demolish => sub {
    confess [1013,"You can't demolish the Halls of Vrbansk."];
};


use constant image => 'hallsofvrbansk';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Halls of Vrbansk';
use constant time_to_build => 0;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
