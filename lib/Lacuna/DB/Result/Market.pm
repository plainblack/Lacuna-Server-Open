package Lacuna::DB::Result::Market;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);

__PACKAGE__->table('market');
__PACKAGE__->add_columns(
    date_offered            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    body_id                 => { data_type => 'int', is_nullable => 0 },
    transfer_type           => { data_type => 'varchar', size => 16, is_nullable => 0 }, # zone | transporter
    ship_id                 => { data_type => 'int', is_nullable => 1 },
    ask                     => { data_type => 'float', size => [11,1], is_nullable => 0},
    payload                 => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
    offer_cargo_space_needed=> { data_type => 'int', default_value => 0 },
    has_water               => { data_type => 'tinyint', default_value => 0 },
    has_energy              => { data_type => 'tinyint', default_value => 0 },
    has_food                => { data_type => 'tinyint', default_value => 0 },
    has_waste               => { data_type => 'tinyint', default_value => 0 },
    has_ore                 => { data_type => 'tinyint', default_value => 0 },
    has_ship                => { data_type => 'tinyint', default_value => 0 },
    has_prisoner            => { data_type => 'tinyint', default_value => 0 },
    has_glyph               => { data_type => 'tinyint', default_value => 0 },
    has_plan                => { data_type => 'tinyint', default_value => 0 },
    x                       => { data_type => 'int', default_value => 0 },
    y                       => { data_type => 'int', default_value => 0 },
    speed                   => { data_type => 'int', default_value => 0 },
    trade_range             => { data_type => 'int', default_value => 0 },
    max_university          => { data_type => 'int', is_nullable => 1 },
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');
__PACKAGE__->belongs_to('ship', 'Lacuna::DB::Result::Ships', 'ship_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_market_zone', fields => ['body_id','transfer_type']);
}

with 'Lacuna::Role::Container';

sub date_offered_formatted {
    my $self = shift;
    return format_date($self->date_offered);
}

sub withdraw {
    my ($self, $body) = @_;
    $body ||= $self->body;
    $self->unload($body);
    if ($self->ship_id) {
        my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($self->ship_id);
        $ship->land->update if defined $ship;
    }
    elsif ($self->transfer_type eq 'transporter') {
        # Note, we  refund 'free' to stop people essentia-laundering 'free' into 'game'
        # by multiple adding/removing trades
        $body->empire->add_essentia({
            amount      => 1,
            reason      => 'Withdrew Transporter Trade',
            type        => 'free',
        });
        $body->empire->update;
    }
    $self->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
