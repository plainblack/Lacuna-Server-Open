package Lacuna::DB::Result::SabenTarget;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';

__PACKAGE__->table('mission');
__PACKAGE__->add_columns(
    target_empire_id        => { data_type => 'int', is_nullable => 0 },
    saben_colony_id        => { data_type => 'int', is_nullable => 0 },
);


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
