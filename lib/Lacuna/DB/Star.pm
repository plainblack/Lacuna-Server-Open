package Lacuna::DB::Star;

use Moose;
extends 'SimpleDB::Class::Item';

__PACKAGE__->set_domain_name('star');
__PACKAGE__->add_attributes(
    name            => { isa => 'Str' },
    is_named        => { isa => 'Str', default => 0 },
    date_created    => { isa => 'DateTime' },
    probed_by       => { isa => 'Str' },
    color           => { isa => 'Str' },
    x               => { isa => 'Int' },
    y               => { isa => 'Int' },
    z               => { isa => 'Int' },
);

__PACKAGE__->has_many('planets', 'Lacuna::DB::Planet', 'star_id');

no Moose;
__PACKAGE__->meta->make_immutable;
