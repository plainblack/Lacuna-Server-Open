package Lacuna::DB::Body;

use Moose;
extends 'SimpleDB::Class::Item';

__PACKAGE__->set_domain_name('body');
__PACKAGE__->add_attributes(
    name            => { isa => 'Str' },
    star_id         => { isa => 'Str' },
    orbit           => { isa => 'Int' },
    class           => { isa => 'Str' },
);

__PACKAGE__->belongs_to('star', 'Lacuna::DB::Star', 'star_id');
__PACKAGE__->recast_using('class');

has image => (
    is      => 'ro',
    default => undef;
);

has minerals => (
    is      => 'ro',
    default => sub { { } },
);

has water => (
    is      => 'ro',
    default => 0,
);

no Moose;
__PACKAGE__->meta->make_immutable;
