package Lacuna::DB::Result::Message;

use Moose;
extends 'Lacuna::DB::Result';
use DateTime;
use Lacuna::Util qw(format_date);

__PACKAGE__->table('message');
__PACKAGE__->add_columns(
    in_reply_to     => { data_type => 'int', size => 11, is_nullable => 1 },
    subject         => { data_type => 'char', size => 30, is_nullable => 0 },
    body            => { data_type => 'mediumtext', is_nullable => 1 },
    date_sent       => { data_type => 'datetime', is_nullable => 0 },
    from_id         => { data_type => 'int', size => 11, is_nullable => 0 },
    from_name       => { data_type => 'char', size => 30, is_nullable => 0 },
    to_id           => { data_type => 'int', size => 11, is_nullable => 1 },
    to_name         => { data_type => 'char', size => 30, is_nullable => 0 },
    recipients      => { data_type => 'mediumtext', is_nullable => 1, 'serializer_class' => 'JSON' },
    tags            => { data_type => 'mediumtext', is_nullable => 1, 'serializer_class' => 'JSON' },
    has_read        => { data_type => 'int', size => 1, default_value => 0 },
    has_replied     => { data_type => 'int', size => 1, default_value => 0 },
    has_archived    => { data_type => 'int', size => 1, default_value => 0 },
    attachments     => { data_type => 'mediumtext', is_nullable => 1, 'serializer_class' => 'JSON' },
);

__PACKAGE__->belongs_to('original_message', 'Lacuna::DB::Result::Message', 'in_reply_to');
__PACKAGE__->belongs_to('sender', 'Lacuna::DB::Result::Empire', 'from_id');
__PACKAGE__->belongs_to('receiver', 'Lacuna::DB::Result::Empire', 'to_id');

sub date_sent_formatted {
    my ($self) = @_;
    return format_date($self->date_sent);
}

sub send {
    my ($class, %params) = @_;
    my $recipients = $params{recipients};
    unless (ref $recipients eq 'ARRAY' && @{$recipients}) {
        push @{$recipients}, $params{to}->name;
    }
    my $self = $class->new(
        simpledb    => $params{simpledb},
        date_sent   => DateTime->now,
        subject     => $params{subject},
        body        => $params{body},
        tags        => $params{tags},
        from_id     => $params{from}->id,
        from_name   => $params{from}->name,
        to_id       => $params{to}->id,
        to_name     => $params{to}->name,
        recipients  => $recipients,
        in_reply_to => $params{in_reply_to},
        attachments => $params{attachments},
    );
    $self->put;
    if (exists $params{in_reply_to} && defined $params{in_reply_to} && $params{in_reply_to} ne '') {
        my $original = $params{simpledb}->domain($class)->find($params{in_reply_to});
        if (defined $original && !$original->has_replied) {
            $original->has_replied(1);
            $original->put;
        }
    }
    return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
