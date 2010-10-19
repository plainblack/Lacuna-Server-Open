package Lacuna::DB::Result::Building::Permanent::Crater;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::Crater';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build a crater. It forms naturally."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade a crater. It forms naturally."];
}

use constant image => 'crater';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Crater';

use constant time_to_build => 0;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
