package Lacuna::DB::Result::Building::Permanent::OracleOfAnid;

use Moose;
use utf8;
use Data::Dumper;


no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::UpgradeWithHalls";
with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::OracleOfAnid';

use constant image => 'oracleanid';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

sub probes {
    my $self = shift;
    return Lacuna->db->resultset('Probes')->search_oracle( {
        body_id     => $self->body->id,
    } );
}

after finish_upgrade => sub {
    my $self = shift;

    $self->body->add_news(30, 'A warning to all enemies foreign and domestic. The government of %s sees all.', $self->body->name);

    my $work_secs = 60;
    if ($self->is_working) {
        my $work_ends = $self->work_ends->clone;
        $work_ends = $work_ends->add(seconds => $work_secs);
        $self->reschedule_work($work_ends);
    }
    else {
        $self->start_work({}, $work_secs);
    }
    $self->update;
};

before demolish => sub {
    my $self = shift;

    $self->probes->delete_all;
};

after update => sub {
    my $self = shift;
};

after finish_work => sub {
    my $self = shift;
    $self->recalc_probes;
    $self->update;
};

sub range {
    my ($self) = @_;

    my $range = $self->effective_level * 1000 * $self->effective_efficiency / 100;

}

use constant name => 'Oracle of Anid';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;

# recalculate all of the virtual probes
#
sub recalc_probes {
    my ($self) = @_;

    # It's easier to delete all the virtual probes, then recreate them.
    $self->probes->search->delete_all;

    my $range = $self->range / 100;

    # get all stars within this range
    my $minus_x = 0 - $self->body->x;
    my $minus_y = 0 - $self->body->y;
    my $stars = Lacuna->db->resultset('Map::Star')->search({
        -and => [
            \[ "ceil(pow(pow(me.x + $minus_x, 2) + pow(me.y + $minus_y, 2), 0.5)) <= $range"],
        ],
    },{
        '+select' => [
            { ceil => \"pow(pow(me.x + $minus_x,2) + pow(me.y + $minus_y,2), 0.5)", '-as' => 'distance' },
        ],
        '+as' => [
            'distance',
        ],
        order_by    => 'distance',
    });

    # Add a virtual probe at each star
    my $body = $self->body;
    if ($body->empire_id) {
        my $empire = $body->empire;
        while (my $star = $stars->next) {
            Lacuna->db->resultset('Probes')->new({
                empire_id   => $empire->id,
                star_id     => $star->id,
                body_id     => $body->id,
                alliance_id => $empire->alliance_id,
                virtual     => 1,
            })->insert;
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

