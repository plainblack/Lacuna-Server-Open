package Lacuna::DB::Result::Captcha;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('captcha');
__PACKAGE__->add_columns(
    riddle                  => { data_type => 'varchar', size => 12, is_nullable => 0 },
    solution                => { data_type => 'varchar', size => 5, is_nullable => 0 },
    guid                    => { data_type => 'varchar', size => 36, is_nullable => 0 },
);


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
