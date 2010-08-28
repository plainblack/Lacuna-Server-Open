package Lacuna::DB::Result::Building::Permanent::Lake;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::Lake';

sub can_build {
    my ($self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return 1;  
    }
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

use constant time_to_build => 0;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
