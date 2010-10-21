package Lacuna::DB::Result::Building::Permanent::OracleOfAnid;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::OracleOfAnid';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build the Oracle of Anid. It was left behind by the Great Race."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade the Oracle of Anid. It was left behind by the Great Race."];
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(50, sprintf('As the Oracle of Anid was untombed on %s today, it began to shimmer with a warm red glow.', $self->body->name));
};

use constant image => 'oracleanid';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Oracle of Anid';

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
