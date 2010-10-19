package Lacuna::DB::Result::Building::Permanent::Beach11;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::Beach11';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build a beach. It forms naturally."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade a beach. It forms naturally."];
}

use constant image => 'beach11';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Beach [11]';

use constant time_to_build => 0;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
