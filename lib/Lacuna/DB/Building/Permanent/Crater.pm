package Lacuna::DB::Building::Permanent::Crater;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

use constant controller_class => 'Lacuna::Building::Crater';

sub check_build_prereqs {
    confess [1013,"You can't build a crater. It forms naturally."];
}

sub can_upgrade {
    confess [1013, "You can't upgrade a crater. It forms naturally."];
}

use constant image => 'crater';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Crater';


no Moose;
__PACKAGE__->meta->make_immutable;
