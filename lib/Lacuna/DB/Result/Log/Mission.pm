package Lacuna::DB::Result::Log::Mission;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('mission_log');
__PACKAGE__->add_columns(
    filename            => { data_type => 'varchar', size => 255 },
    offers              => { data_type => 'int', default_value => 0 },
    skips               => { data_type => 'int', default_value => 0 },
    skip_uni_level      => { data_type => 'bigint', default_value => 0 },
    completes           => { data_type => 'int', default_value => 0 },
    complete_uni_level  => { data_type => 'bigint', default_value => 0 },
    seconds_to_complete => { data_type => 'bigint', default_value => 0 },
    incompletes         => { data_type => 'int', default_value => 0 },
);

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
