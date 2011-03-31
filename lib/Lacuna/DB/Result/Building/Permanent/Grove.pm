package Lacuna::DB::Result::Building::Permanent::Grove;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::Grove';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build a grove of trees. It forms naturally."];
};

use constant image => 'grove';

use constant name => 'Grove of Trees';
use constant max_instances_per_planet => 1;

use constant water_to_build => 1;
use constant time_to_build => 1;
use constant energy_production => 1; 

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
