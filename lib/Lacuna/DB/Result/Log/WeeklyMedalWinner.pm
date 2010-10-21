package Lacuna::DB::Result::Log::WeeklyMedalWinner;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log::WithEmpire';

__PACKAGE__->table('weekly_medal_winner');
__PACKAGE__->add_columns(
    medal_id                => { data_type => 'int', is_nullable => 0 },
    medal_name              => { data_type => 'varchar', size => 50, is_nullable => 0 },
    times_earned            => { data_type => 'int', is_nullable => 0 },
    medal_image             => { data_type => 'varchar', size => 50, is_nullable => 0 },
);


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
