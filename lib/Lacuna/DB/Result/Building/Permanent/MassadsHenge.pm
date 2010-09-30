package Lacuna::DB::Result::Building::Permanent::MassadsHenge;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::MassadsHenge';

sub can_build {
    my ($self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return 1;  
    }
    confess [1013,"You can't build Massad's Henge. It was left behind by the Great Race."];
}

sub can_upgrade {
    confess [1013, "You can't upgrade Massad's Henge. It was left behind by the Great Race."];
}

use constant image => 'massadshenge';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

#after finish_upgrade => sub {
#    my $self = shift;
#    if ($self->level == 1) {
#        $self->body->add_news(50, sprintf('The discovery of Massad\'s Henge on %s has historians puzzled. It was assumed to only be legend.', $self->body->name));
#    }
#};

use constant name => 'Massad\'s Henge';

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
