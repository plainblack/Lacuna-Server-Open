package Lacuna::DB::Building::Permanent::RockyOutcrop;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

use constant controller_class => 'Lacuna::Building::RockyOutcrop';

sub check_build_prereqs {
    confess [1013,"You can't build a rocky outcropping. It forms naturally."];
}

sub can_upgrade {
    confess [1013, "You can't upgrade a rocky outcropping. It forms naturally."];
}

use constant image => 'rockyoutcrop';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Rocky Outcropping';


no Moose;
__PACKAGE__->meta->make_immutable;
