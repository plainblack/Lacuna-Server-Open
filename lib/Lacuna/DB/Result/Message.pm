package Lacuna::DB::Result::Message;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use DateTime;
use Lacuna::Util qw(format_date);

__PACKAGE__->table('message');
__PACKAGE__->add_columns(
    in_reply_to     => { data_type => 'int', size => 11, is_nullable => 1 },
    subject         => { data_type => 'varchar', size => 64, is_nullable => 0 },
    body            => { data_type => 'mediumtext', is_nullable => 1 },
    date_sent       => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    from_id         => { data_type => 'int', size => 11, is_nullable => 0 },
    from_name       => { data_type => 'varchar', size => 30, is_nullable => 0 },
    to_id           => { data_type => 'int', size => 11, is_nullable => 1 },
    to_name         => { data_type => 'varchar', size => 30, is_nullable => 0 },
    recipients      => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
    tag             => { data_type => 'varchar', size => 15, is_nullable => 1 },
    has_read        => { data_type => 'tinyint', default_value => 0, is_nullable => 0 },
    has_replied     => { data_type => 'tinyint', default_value => 0, is_nullable => 0 },
    has_archived    => { data_type => 'tinyint', default_value => 0, is_nullable => 0 },
    has_trashed     => { data_type => 'tinyint', default_value => 0, is_nullable => 0 },
    attachments     => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
    repeat_check    => { data_type => 'varchar', size => 30, is_nullable => 1 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_repeat_check_date_sent', fields => ['repeat_check', 'date_sent']);
    $sqlt_table->add_index(name => 'idx_recent_messages', fields => [qw(has_archived has_read to_id date_sent)]);
    $sqlt_table->add_index(name => 'idx_inbox_only', fields => [qw(has_archived to_id date_sent)]);
    $sqlt_table->add_index(name => 'idx_trash_only', fields => [qw(has_trashed to_id date_sent)]);
}

__PACKAGE__->belongs_to('sender', 'Lacuna::DB::Result::Empire', 'from_id');
__PACKAGE__->belongs_to('receiver', 'Lacuna::DB::Result::Empire', 'to_id');

sub date_sent_formatted {
    my ($self) = @_;
    return format_date($self->date_sent);
}

for my $func (qw(insert update delete)) {
    after $func => sub {
        my $self = shift;

        $self->receiver->recalc_messages;
    };
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
