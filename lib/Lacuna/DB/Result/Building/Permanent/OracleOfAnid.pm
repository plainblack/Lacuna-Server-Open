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
    return Lacuna->db->resultset('Probes')->search_oracle;
}

after finish_upgrade => sub {
    my $self = shift;

    $self->recalc_probes;
    $self->body->add_news(30, sprintf('A warning to all enemies foreign and domestic. The government of %s sees all.', $self->body->name));
};

before demolish => sub {
    my $self = shift;

    $self->probes->delete_all;
};

after update => sub {
    my $self = shift;

    $self->recalc_probes;
};

sub range {
    my ($self) = @_;

    my $range = $self->level * 1000 * $self->efficiency / 100;

}

use constant name => 'Oracle of Anid';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;

# recalculate all of the virtual probes
#
sub recalc_probes {
    my ($self) = @_;

    # It's easier to delete all the virtual probes, then recreate them.
    $self->probes->delete_all;

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
    print STDERR "THERE ARE [".$stars->count."] STARS IN RANGE\n";    

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

