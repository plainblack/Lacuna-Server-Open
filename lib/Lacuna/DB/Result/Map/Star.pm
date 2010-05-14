package Lacuna::DB::Result::Map::Star;

use Moose;
extends 'Lacuna::DB::Result::Map';
use Lacuna::Util;

__PACKAGE__->table('star');
__PACKAGE__->add_columns(
    color                   => { data_type => 'char', size => 7, is_nullable => 0 },
);

__PACKAGE__->has_many('bodies', 'Lacuna::DB::Result::Map::Body', 'star_id');


sub get_status {
    my ($self, $empire) = @_;
    my $out = {
        color       => $self->color,
        name        => $self->name,
        id          => $self->id,
        x           => $self->x,
        y           => $self->y,
    };
    if (defined $empire) {
        my @alignments;
        if ($self->id ~~ $empire->probed_stars) {
            my $bodies = $self->bodies->search({ class => ['like', 'Lacuna::DB::Result::Map::Body::Planet%'] });
            while (my $body = $bodies->next) {
                if ($body->empire_id eq $empire->id) {
                    push @alignments, 'self';
                }
                elsif ($body->empire_id ne 'None') {
                    push @alignments, 'hostile';
                }
            }
            if (@alignments) {
                if ('self' ~~ @alignments && 'hostile' ~~ @alignments && 'ally' ~~ @alignments) {
                    $out->{alignments} = 'self-hostile-ally';
                }
                elsif ('self' ~~ @alignments && 'hostile' ~~ @alignments) {
                    $out->{alignments} = 'self-hostile';
                }
                elsif ('self' ~~ @alignments && 'ally' ~~ @alignments) {
                    $out->{alignments} = 'self-ally';
                }
                elsif ('hostile' ~~ @alignments && 'ally' ~~ @alignments) {
                    $out->{alignments} = 'hostile-ally';
                }
                elsif ('self' ~~ @alignments) {
                    $out->{alignments} = 'self';
                }
                elsif ('hostile' ~~ @alignments) {
                    $out->{alignments} = 'hostile';
                }
                elsif ('ally' ~~ @alignments) {
                    $out->{alignments} = 'ally';
                }
            }
            else {
                $out->{alignments} = 'probed';
            }
        }
        else {
            $out->{alignments} = 'unprobed';
        }
    }
    return $out;
}




no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
