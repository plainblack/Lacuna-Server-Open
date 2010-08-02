package Lacuna::DB::Result::Species;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util;
use Lacuna::Verify;

__PACKAGE__->table('species');
__PACKAGE__->add_columns(
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    empire_id               => { data_type => 'int', size => 11, is_nullable => 1 },
    description             => { data_type => 'text', is_nullable => 1 },
    min_orbit               => { data_type => 'tinyint', default_value => 3 },
    max_orbit               => { data_type => 'tinyint', default_value => 3 },
    manufacturing_affinity  => { data_type => 'tinyint', default_value => 4 }, # cost of building new stuff
    deception_affinity      => { data_type => 'tinyint', default_value => 4 }, # spying ability
    research_affinity       => { data_type => 'tinyint', default_value => 4 }, # cost of upgrading
    management_affinity     => { data_type => 'tinyint', default_value => 4 }, # speed to build
    farming_affinity        => { data_type => 'tinyint', default_value => 4 }, # food
    mining_affinity         => { data_type => 'tinyint', default_value => 4 }, # minerals
    science_affinity        => { data_type => 'tinyint', default_value => 4 }, # energy, propultion, and other tech
    environmental_affinity  => { data_type => 'tinyint', default_value => 4 }, # waste and water
    political_affinity      => { data_type => 'tinyint', default_value => 4 }, # happiness
    trade_affinity          => { data_type => 'tinyint', default_value => 4 }, # speed of cargoships, and amount of cargo hauled
    growth_affinity         => { data_type => 'tinyint', default_value => 4 }, # price and speed of colony ships, and planetary command center start level
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_empire_id', fields => ['empire_id']);
}


__PACKAGE__->has_many('empires', 'Lacuna::DB::Result::Empire', 'species_id', {join_type => 'left', cascade_delete => 0});
__PACKAGE__->belongs_to('creator', 'Lacuna::DB::Result::Empire', 'empire_id', { is_foreign_key_constraint => 0 });


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
