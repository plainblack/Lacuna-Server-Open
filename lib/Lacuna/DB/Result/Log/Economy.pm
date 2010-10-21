package Lacuna::DB::Result::Log::Economy;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('economy_log');
__PACKAGE__->add_columns(
    date_stamp          => { data_type => 'date', is_nullable => 0 },
    total_users         => { data_type => 'int', default_value => 0 },
    purchases_30        => { data_type => 'int', default_value => 0 },
    purchases_100       => { data_type => 'int', default_value => 0 },
    purchases_200       => { data_type => 'int', default_value => 0 },
    purchases_600       => { data_type => 'int', default_value => 0 },
    purchases_1300      => { data_type => 'int', default_value => 0 },
    in_purchase         => { data_type => 'int', default_value => 0 },
    in_trade            => { data_type => 'int', default_value => 0 },
    in_redemption       => { data_type => 'int', default_value => 0 },
    in_vein             => { data_type => 'int', default_value => 0 },
    in_vote             => { data_type => 'int', default_value => 0 },
    in_tutorial         => { data_type => 'int', default_value => 0 },
    in_mission          => { data_type => 'int', default_value => 0 },
    in_other            => { data_type => 'int', default_value => 0 },
    out_boost           => { data_type => 'int', default_value => 0 },
    out_mission         => { data_type => 'int', default_value => 0 },
    out_recycle         => { data_type => 'int', default_value => 0 },
    out_ship            => { data_type => 'int', default_value => 0 },
    out_spy             => { data_type => 'int', default_value => 0 },
    out_glyph           => { data_type => 'int', default_value => 0 },
    out_party           => { data_type => 'int', default_value => 0 },
    out_building        => { data_type => 'int', default_value => 0 },
    out_trade           => { data_type => 'int', default_value => 0 },
    out_delete          => { data_type => 'int', default_value => 0 },
    out_other           => { data_type => 'int', default_value => 0 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_date_stamp', fields => ['date_stamp']);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
