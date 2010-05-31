package Lacuna::DB::Result::Log::Essentia;

use Moose;
extends 'Lacuna::DB::Result::Log';
use Lacuna::Util;

__PACKAGE__->table('essentia_log');
__PACKAGE__->add_columns(
    api_key             => { data_type => 'char', size => 40, is_nullable => 1 },
    amount              => { data_type => 'int', size => 11, is_nullable => 0 },
    description         => { data_type => 'char', size => 90, is_nullable => 0 },
);

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
