package Lacuna::DB::Result::Trades;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use feature "switch";

__PACKAGE__->table('trades');
__PACKAGE__->add_columns(
    body_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    transfer_type           => { data_type => 'varchar', size => 16, is_nullable => 0 }, # zone | transporter
    ships_holding_goods     => { data_type => 'mediumtext', is_nullable => 1, 'serializer_class' => 'JSON' },
    ask_description         => { data_type => 'varchar', size => 30, is_nullable => 0 }, # 100 Corn, 500 Bauxite
    ask_type                => { data_type => 'varchar', size => 11, is_nullable => 0 }, # ore, bauxite, water, energy, food, waste, essentia
    ask_quantity            => { data_type => 'int', size => 11, default_value => 1 },
    offer_cargo_space_needed=> { data_type => 'int', size => 11, default_value => 0 },
    offer_description       => { data_type => 'varchar', size => 100, is_nullable => 0 }, # 1000 Corn, Empire Name Prisoner, Colony Ship (Speed: 12, Cargo: 0), etc
    offer_object_id         => { data_type => 'int', size => 11, is_nullable => 1 }, 
    offer_type              => { data_type => 'varchar', size => 11, is_nullable => 0 }, # ship, ore, water, energy, food, waste, essentia, prisoner, glyph, plan
    offer_sub_type          => { data_type => 'varchar', size => 30, is_nullable => 1 }, # corn, human, colony_ship, etc
    offer_quantity          => { data_type => 'int', size => 11, default_value => 1 },
    offer_rank_1            => { data_type => 'int', default_value => 0 },
    offer_rank_2            => { data_type => 'int', default_value => 0 }, 
);

sub withdraw {
    my ($self, $body) = @_;
    $body ||= Lacuna->db->resultset('Lacuna::DB::Result::Map::Body');
    given ($self->offer_type) {
        when ([qw(ore water energy waste food)]) {
            my $add = 'add_'.$self->offer_sub_type;
            $body->$add($self->offer_quantity);
            $body->update;
        }
        when ('essentia') {
            $body->empire->add_essentia($self->offer_quantity,'trade');
            $body->empire->update;
        }
        when ('ship') {
            my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ship')->find($self->offer_object_id);
            $ship->task('Docked');
            $ship->update;
        }
        when ('glyph') {
            
        }
        when ('plan') {
            Lacuna->db->resultset('Lacuna::DB::Result::Plans')->new({
                body_id             => $body->id,
                class               => $self->offer_sub_type,
                level               => $self->offer_rank_1,
                extra_build_level   => $self->offer_rank_2,
            })->insert;
        }
        when ('prisoner') {
            my $spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($self->offer_object_id);
            $spy->task('Idle');
            $spy->update;
        }
    }
    $self->delete;
}

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_trade_sorting', fields => ['transfer_type','offer_type','offer_sub_type','offer_quantity','offer_rank_1','offer_rank_2']);
}

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
