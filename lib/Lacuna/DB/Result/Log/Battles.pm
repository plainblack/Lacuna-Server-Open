package Lacuna::DB::Result::Log::Battles;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log';
use Lacuna::Util;

__PACKAGE__->table('battle_log');
__PACKAGE__->add_columns(
    attacking_empire_id     => { data_type => 'int', size => 11, is_nullable => 0 },
    attacking_empire_name   => { data_type => 'varchar', size => 30, is_nullable => 0 },
    attacking_body_id       => { data_type => 'int', size => 11, is_nullable => 0 },
    attacking_body_name     => { data_type => 'varchar', size => 30, is_nullable => 0 },
    attacking_unit_name     => { data_type => 'varchar', size => 60, is_nullable => 0 },
    attacking_type          => { data_type => 'varchar', size => 60, is_nullable => 0 },
    attacking_number        => { data_type => 'int', size => 11, is_nullable => 0 },
    defending_empire_id     => { data_type => 'int', size => 11, is_nullable => 1 },
    defending_empire_name   => { data_type => 'varchar', size => 30, is_nullable => 1 },
    defending_body_id       => { data_type => 'int', size => 11, is_nullable => 0 },
    defending_body_name     => { data_type => 'varchar', size => 30, is_nullable => 0 },
    defending_unit_name     => { data_type => 'varchar', size => 60, is_nullable => 0 },
    defending_type          => { data_type => 'varchar', size => 60, is_nullable => 0 },
    defending_number        => { data_type => 'int', size => 11, is_nullable => 0 },
    victory_to              => { data_type => 'varchar', size => 8, is_nullable => 0 },
    attacked_body_id        => { data_type => 'int', size => 11, is_nullable => 0 },
    attacked_body_name      => { data_type => 'varchar', size => 30, is_nullable => 0 },
    attacked_empire_id      => { data_type => 'int', size => 11, is_nullable => 1 },
    attacked_empire_name    => { data_type => 'varchar', size => 30, is_nullable => 1 },
);

after 'sqlt_deploy_hook' => sub {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_datestamp', fields => ['date_stamp']);
    $sqlt_table->add_index(name => 'idx_attacking_empire_id', fields => ['attacking_empire_id']);
    $sqlt_table->add_index(name => 'idx_attacking_empire_name', fields => ['attacking_empire_name']);
    $sqlt_table->add_index(name => 'idx_attacking_body_id', fields => ['attacking_body_id']);
    $sqlt_table->add_index(name => 'idx_attacking_body_name', fields => ['attacking_body_name']);
    $sqlt_table->add_index(name => 'idx_defending_empire_id', fields => ['defending_empire_id']);
    $sqlt_table->add_index(name => 'idx_defending_empire_name', fields => ['defending_empire_name']);
    $sqlt_table->add_index(name => 'idx_defending_body_id', fields => ['defending_body_id']);
    $sqlt_table->add_index(name => 'idx_defending_body_name', fields => ['defending_body_name']);
};

after insert => sub {
    my $self = shift;

    # only store summary information for attacking or defending AI
    return if ($self->attacking_empire_id > 1 and (not defined $self->defending_empire_id or $self->defending_empire_id > 1 ));

    my $summary_rs = Lacuna->db->resultset('Lacuna::DB::Result::AIBattleSummary');
    my $ai_battle_summary = $summary_rs->search({
        attacking_empire_id     => $self->attacking_empire_id,
        defending_empire_id     => $self->defending_empire_id,
    })->first;
    if (not $ai_battle_summary) {
        $ai_battle_summary = $summary_rs->create({
            attacking_empire_id => $self->attacking_empire_id,
            defending_empire_id => $self->defending_empire_id,
            attack_victories    => 0,
            defense_victories   => 0,
        });
    }
    $ai_battle_summary->attack_victories($ai_battle_summary->attack_victories + $self->attacking_number)
        if $self->victory_to eq 'attacker';
    $ai_battle_summary->defense_victories($ai_battle_summary->defense_victories + $self->defending_number)
        if $self->victory_to eq 'defender';
    $ai_battle_summary->update;
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
