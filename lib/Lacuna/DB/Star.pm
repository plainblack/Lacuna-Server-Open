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
    name_cname           => { isa => 'Str' },
    is_named        => { isa => 'Str', default => '0' },
    date_created    => { isa => 'DateTime' },
    color           => { isa => 'Str' },
    x               => { isa => 'Int' },
    y               => { isa => 'Int' },
    z               => { isa => 'Int' },
);

__PACKAGE__->has_many('bodies', 'Lacuna::DB::Body', 'star_id');
__PACKAGE__->has_many('planets', 'Lacuna::DB::Body::Planet', 'star_id');

no Moose;
__PACKAGE__->meta->make_immutable;
