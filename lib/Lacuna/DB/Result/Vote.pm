package Lacuna::DB::Result::Vote;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use DateTime;

__PACKAGE__->table('vote');
__PACKAGE__->add_columns(
    proposition_id          => { data_type => 'int', is_nullable => 0 },
    empire_id               => { data_type => 'int', is_nullable => 0 },
    vote                    => { data_type => 'int', is_nullable => 0, default_value => 0 },
); 

__PACKAGE__->belongs_to('proposition', 'Lacuna::DB::Result::Proposition', 'proposition_id');
__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id');


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
