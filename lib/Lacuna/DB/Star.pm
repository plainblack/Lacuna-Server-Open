package Lacuna::DB::Star;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util;

__PACKAGE__->set_domain_name('star');
__PACKAGE__->add_attributes(
    name            => { isa => 'Str', 
        trigger => sub {
            my ($self, $new, $old) = @_;
            $self->name_cname(Lacuna::Util::cname($new));
        },
    },
    name_cname      => { isa => 'Str' },
    date_created    => { isa => 'DateTime' },
    color           => { isa => 'Str' },
    x               => { isa => 'Int' },
    y               => { isa => 'Int' },
    z               => { isa => 'Int' },
    zone            => { isa => 'Str' },
);

with 'Lacuna::Role::Zoned';

__PACKAGE__->has_many('bodies', 'Lacuna::DB::Body', 'star_id', mate => 'star');
__PACKAGE__->has_many('planets', 'Lacuna::DB::Body::Planet', 'star_id', mate => 'star');


sub get_status {
    my ($self, $empire) = @_;
    my $out = {
        color       => $self->color,
        name        => $self->name,
        id          => $self->id,
        x           => $self->x,
        y           => $self->y,
        z           => $self->z,
    };
    if (defined $empire) {
        my @alignments;
        if ($self->id ~~ $empire->probed_stars) {
            my $bodies = $self->bodies(where => { class => ['like', 'Lacuna::DB::Body::Planet%'] });
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
__PACKAGE__->meta->make_immutable;
