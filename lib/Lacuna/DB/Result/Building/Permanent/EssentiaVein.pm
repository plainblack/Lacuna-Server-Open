package Lacuna::DB::Result::Building::Permanent::EssentiaVein;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::EssentiaVein';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build an Essentia Vein. It forms naturally."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade an Essentia Vein. It forms naturally."];
}

use constant image => 'essentiavein';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('Though officials on %s tried to keep it secret, news of the discovery of an Essentia vein broke.', $self->body->name));
};

use constant name => 'Essentia Vein';

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
