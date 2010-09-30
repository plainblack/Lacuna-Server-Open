package Lacuna::DB::Result::Building::Permanent::Grove;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::Grove';

sub can_build {
    my ($self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return 1;  
    }
    confess [1013,"You can't build a grove of trees. It forms naturally."];
}

use constant image => 'grove';

use constant name => 'Grove of Trees';

use constant water_to_build => 1;
use constant time_to_build => 1;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
