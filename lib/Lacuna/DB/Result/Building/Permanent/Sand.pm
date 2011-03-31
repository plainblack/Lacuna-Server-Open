package Lacuna::DB::Result::Building::Permanent::Sand;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::Sand';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build sand. It forms naturally."];
};

use constant image => 'sand';

use constant name => 'Patch of Sand';
use constant max_instances_per_planet => 3;

use constant ore_to_build => 1;
use constant time_to_build => 1;
use constant ore_production => 1; 
no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
