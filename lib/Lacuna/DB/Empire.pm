package Lacuna::DB::Empire;

use Moose;
extends 'SimpleDB::Class::Domain';

__PACKAGE__->set_name('empire');
__PACKAGE__->add_attributes({
    name            => { isa => 'Str' },
    date_created    => { isa => 'DateTime' },
    username        => { isa => 'Str' },
    password        => { isa => 'Str' },
    species_id      => { isa => 'Str' },
});

__PACKAGE__->belongs_to('species', 'Lacuna::DB::Species', 'species_id');

no Moose;
__PACKAGE__->meta->make_immutable;
