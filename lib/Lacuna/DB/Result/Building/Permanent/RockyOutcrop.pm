package Lacuna::DB::Result::Building::Permanent::RockyOutcrop;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::RockyOutcrop';

sub can_upgrade {
    confess [1013, "You can't upgrade a rocky outcropping. It forms naturally."];
}

use constant image => 'rockyoutcrop';
use constant ore_production => 50; 

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Rocky Outcropping';
use constant time_to_build => 0;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
