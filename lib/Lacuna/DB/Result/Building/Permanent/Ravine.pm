package Lacuna::DB::Result::Building::Permanent::Ravine;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::Ravine';

sub can_build {
    my ($self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return 1;  
    }
    confess [1013,"You can't build a Ravine. It forms naturally."];
}

sub can_upgrade {
    confess [1013, "You can't upgrade a Ravine. It forms naturally."];
}

use constant image => 'ravine';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('A tectonic shift shook the inhabitants of %s today as the ground quaked beneath their feet.', $self->body->name));
};

use constant name => 'Ravine';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
