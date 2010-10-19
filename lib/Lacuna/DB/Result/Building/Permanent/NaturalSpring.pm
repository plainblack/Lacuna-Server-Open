package Lacuna::DB::Result::Building::Permanent::NaturalSpring;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::NaturalSpring';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build a Natural Spring. It forms naturally."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade a Natural Spring. It forms naturally."];
}

use constant image => 'naturalspring';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('Worries of drought ended today as a natural spring bubbled to the surface of %s today.', $self->body->name));
};

use constant name => 'Natural Spring';
use constant water_production => 4000;

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
