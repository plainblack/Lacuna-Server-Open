package Lacuna::DB::Result::Building::Permanent::Lake;

use Moose;
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::Building::Lake';

sub check_build_prereqs {
    confess [1013,"You can't build a lake. It forms naturally."];
}

sub can_upgrade {
    confess [1013, "You can't upgrade a lake. It forms naturally."];
}

use constant image => 'lake';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Lake';


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
