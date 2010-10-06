package Lacuna::DB::Result::Building::Permanent::AlgaePond;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';
use Lacuna::Util qw(randint);

use constant controller_class => 'Lacuna::RPC::Building::AlgaePond';

sub can_build {
    my ($self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return 1;  
    }
    confess [1013,"You can't build an Algae Pond. It forms naturally."];
}

sub can_upgrade {
    confess [1013, "You can't upgrade an Algae Pond. It forms naturally."];
}

use constant image => 'algaepond';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('This is no fisherman\'s tale. A local fisherman caught a '.randint(1,9).' meter Rakl out of an algae pond on %s.', $self->body->name));
};

use constant name => 'Algae Pond';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;
use constant algae_production => 4000; 


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
