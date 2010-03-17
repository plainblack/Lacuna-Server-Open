package Lacuna::DB::Building::Permanent::Lake;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

use constant controller_class => 'Lacuna::Building::Lake';

sub check_build_prereqs {
    confess [1013,"You can't build a lake. It forms naturally."];
}

use constant image => 'lake';

use constant name => 'Lake';


no Moose;
__PACKAGE__->meta->make_immutable;
