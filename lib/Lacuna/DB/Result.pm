package Lacuna::DB::Result;

no warnings qw(uninitialized);
use namespace::autoclean -except => ['meta'];

use base 'Lacuna::DB::ResultBase';

__PACKAGE__->table('noexist_basetable');
__PACKAGE__->add_columns(
    id      => { data_type => 'int', size => 11, is_auto_increment => 1 },
);
__PACKAGE__->set_primary_key('id');

1;
