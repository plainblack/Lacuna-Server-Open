package Lacuna::DB::Body;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util;

__PACKAGE__->set_domain_name('body');
__PACKAGE__->add_attributes(
    name            => { isa => 'Str', 
        trigger => sub {
            my ($self, $new, $old) = @_;
            $self->cname(Lacuna::Util::cname($new));
        },
    },
    cname           => { isa => 'Str' },
    star_id         => { isa => 'Str' },
    orbit           => { isa => 'Int' },
    x               => { isa => 'Int' }, # indexed here to speed up
    y               => { isa => 'Int' }, # searching of planets based
    z               => { isa => 'Int' }, # on stor location
    class           => { isa => 'Str' },
);

__PACKAGE__->belongs_to('star', 'Lacuna::DB::Star', 'star_id');
__PACKAGE__->recast_using('class');

has image => (
    is      => 'ro',
    default => undef,
);

has minerals => (
    is      => 'ro',
    default => sub { { } },
);

has water => (
    is      => 'ro',
    default => 0,
);

sub recalc_stats { } # interface

no Moose;
__PACKAGE__->meta->make_immutable;
