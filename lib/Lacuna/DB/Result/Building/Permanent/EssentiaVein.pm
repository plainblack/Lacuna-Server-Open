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

sub can_downgrade {
    confess [1013, "You can't downgrade an Essentia Vein."];
}

use constant image => 'essentiavein';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;

    $self->body->add_news(30, sprintf('Though officials on %s tried to keep it secret, news of the discovery of an Essentia vein broke.', $self->body->name));
    # Removed any scheduled work that is already running
    # Reschedule work.
    #
    my $work_ends;
    if ($self->is_working) {
        $work_ends = $self->work_ends->clone;
    }
    else {
        $work_ends = DateTime->now;
    }
    $work_ends = $work_ends->add(seconds => 60 * 60 * 24 * 60);
    $self->reschedule_work($work_ends);
    $self->update;

};

after finish_work => sub {
    my $self = shift;
    my $body = $self->body;
    $body->needs_surface_refresh(1);
    $body->needs_recalc(1);
    $body->update;
    $self->update({class=>'Lacuna::DB::Result::Building::Permanent::Crater'});
};

use constant name => 'Essentia Vein';

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
