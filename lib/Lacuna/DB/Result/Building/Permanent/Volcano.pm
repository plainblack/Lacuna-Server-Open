package Lacuna::DB::Result::Building::Permanent::Volcano;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::Volcano';

sub can_build {
    my ($self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return 1;  
    }
    confess [1013,"You can't build a Volcano. It forms naturally."];
}

sub can_upgrade {
    confess [1013, "You can't upgrade a Volcano. It forms naturally."];
}

use constant image => 'volcano';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Volcano';
use constant ore_production => 4000;

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
