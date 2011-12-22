package Lacuna::DB::Result::AIBattleSummary;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('ai_battle_summary');
__PACKAGE__->add_columns(
    id                  => { data_type => 'int', size => 11, is_nullable => 0 },
    attacking_empire_id => { data_type => 'int', size => 11, is_nullable => 0 },
    defending_empire_id => { data_type => 'int', size => 11, is_nullable => 0 },
    attack_victories    => { data_type => 'int', size => 11, is_nullable => 0 },
    defense_victories   => { data_type => 'int', size => 11, is_nullable => 0 },
    attack_spy_hours    => { data_type => 'int', size => 11, is_nullable => 0 },
); 

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'attacking_empire_id');
__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'defending_empire_id');

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
