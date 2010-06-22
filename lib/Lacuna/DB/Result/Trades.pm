package Lacuna::DB::Result::Trades;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use feature "switch";

__PACKAGE__->table('trades');
__PACKAGE__->add_columns(
    date_offered            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    body_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    transfer_type           => { data_type => 'varchar', size => 16, is_nullable => 0 }, # zone | transporter
    ship_id                 => { data_type => 'int', size => 11, is_nullable => 1 },
    ask_description         => { data_type => 'varchar', size => 30, is_nullable => 0 }, # 100 Corn, 500 Bauxite
    ask_type                => { data_type => 'varchar', size => 11, is_nullable => 0 }, # ore, bauxite, water, energy, food, waste, essentia
    ask_quantity            => { data_type => 'int', size => 11, default_value => 1 },
    payload                 => { data_type => 'mediumtext', is_nullable => 1, 'serializer_class' => 'JSON' },
    offer_cargo_space_needed=> { data_type => 'int', size => 11, default_value => 0 },
    offer_description       => { data_type => 'varchar', size => 100, is_nullable => 0 }, # 1000 Corn, Empire Name Prisoner, Colony Ship (Speed: 12, Cargo: 0), etc
    offer_object_id         => { data_type => 'int', size => 11, is_nullable => 1 }, 
    offer_type              => { data_type => 'varchar', size => 11, is_nullable => 0 }, # ship, ore, water, energy, food, waste, essentia, prisoner, glyph, plan
    offer_sub_type          => { data_type => 'varchar', size => 30, is_nullable => 1 }, # corn, human, colony_ship, etc
    offer_quantity          => { data_type => 'int', size => 11, default_value => 1 },
    offer_rank_1            => { data_type => 'int', default_value => 0 },
    offer_rank_2            => { data_type => 'int', default_value => 0 }, 
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_trade_sorting', fields => ['transfer_type','offer_type','offer_sub_type','offer_quantity','offer_rank_1','offer_rank_2']);
}

with 'Lacuna::Role::Container';

sub date_offered_formatted {
    my $self = shift;
    return format_date($self->date_offered);
}

sub withdraw {
    my ($self, $body) = @_;
    $body ||= Lacuna->db->resultset('Lacuna::DB::Result::Map::Body');
    $self->unload($body);
    if ($self->ship_id) {
        my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($self->ship_id);
        $ship->land if defined $ship;
    }
    $self->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
