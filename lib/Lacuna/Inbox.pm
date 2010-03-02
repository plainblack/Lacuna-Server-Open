package Lacuna::Inbox;

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use DateTime;
use Lacuna::Util qw(cname);
use Lacuna::Verify;

has simpledb => (
    is      => 'ro',
    required=> 1,
);

with 'Lacuna::Role::Sessionable';

sub read_message {
    my ($self, $session_id, $message_id) = @_;
    my $message = $self->simpledb->domain('message')->find($message_id);
    unless (defined $message) {
        confess [1002, 'Message does not exist.', $message_id];
    }
    my $empire = $self->get_empire_by_session($session_id);
    unless ($empire->id ~~ ($message->from_id, $message->to_id)) {
        confess [1010, "You can't view a message that isn't yours.", $message_id];
    }
    if ($empire->id eq $message->to_id && !$message->has_read) {
        $message->has_read(1);
        $message->put;
    }
    return {
        status  => $empire->get_status,
        message => {
            id          => $message->id,
            from        => $message->from_name,
            to          => $message->to_name,
            subject     => $message->subject,
            body        => $message->body,
            date        => $message->date_sent_formatted,
            has_read    => $message->has_read,
            has_replied => $message->has_replied,
            has_archived=> $message->has_archived,
            in_reply_to => $message->in_reply_to,
            recipients  => $message->recipients,
        },
    };
}

sub archive_messages {
    my ($self, $session_id, $message_ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $messages = $self->simpledb->domain('message');
    foreach my $id (@{$message_ids}) {
        my $message = $messages->find($id);
        if ($empire->id eq $message->to_id && !$message->has_archived) {
            $message->has_archived(1);
            $message->put;
        }
    }
    return $self->view_inbox($empire);
}

sub send_message {
    my ($self, $session_id, $recipients, $subject, $body, $options) = @_;
    Lacuna::Verify->new(content=>\$subject, throws=>[1005,'Invalid subject.',$subject])
        ->not_empty
        ->no_restricted_chars
        ->length_lt(100)
        ->no_profanity;
    Lacuna::Verify->new(content=>\$body, throws=>[1005,'Invalid message.',$body])
        ->not_empty
        ->no_restricted_chars
        ->no_profanity;
    my $empire = $self->get_empire_by_session($session_id);
    my @sent;
    my @unknown;
    my @to;
    foreach my $name (split /\s*,\s*/, $recipients) {
        next if $name eq '';
        my $user = $self->simpledb->domain('empire')->search(where=>{cname => cname($name)})->next;
        if (defined $user) {
            push @sent, $user->name;
            push @to, $user;
        }
        else {
            push @unknown, $name;
        }
    }
    foreach my $to (@to) {
        Lacuna::DB::Message->send(
            simpledb    => $self->simpledb,
            from        => $empire,
            subject     => $subject,
            message     => $body,
            to          => $to,
            in_reply_to => $options->{in_reply_to},
            recipients  => @sent,
        );
    }
    return {
        message => {
            sent    => \@sent,
            unknown => \@unknown,
        },
        status  => $empire->get_status,
    };
}

sub view_inbox {
    my $self = shift;
    my $session_id = shift;
    my $empire = $self->get_empire_by_session($session_id);
    my $where = {
        has_archived    => ['!=', 1],
        to_id           => $empire->id,
    };
    return $self->view_messages($where, $empire, @_);
}

sub view_archived {
    my $self = shift;
    my $session_id = shift;
    my $empire = $self->get_empire_by_session($session_id);
    my $where = {
        has_archived    => 1,
        to_id           => $empire->id,
    };
    return $self->view_messages($where, $empire, @_);
}

sub view_sent {
    my $self = shift;
    my $session_id = shift;
    my $empire = $self->get_empire_by_session($session_id);
    my $where = {
        has_archived    => 1,
        from_id         => $empire->id,
    };
    return $self->view_messages($where, $empire, @_);
}

sub view_messages {
    my ($self, $where, $empire, $page_number) = @_;
    $page_number ||= 1;
    my $messages = $self->simpledb->domain('message')->search(
        where       => $where,
        order_by    => 'date_sent',
    )->paginate(25, $page_number);
    my @box;
    while (my $message = $messages->next) {
        push @box, {
            id          => $message->id,
            subject     => $message->subject,
            date        => $message->date_sent_formated,
            from        => $message->from_name,
            has_read    => $message->has_read,
            has_replied => $message->has_replied,
        };
    }
    return {
        messages    => \@box,
        status      => $empire->get_status,
    };
}

__PACKAGE__->register_rpc_method_names(qw(view_inbox view_archived view_sent send_message read_message archive_messages));


no Moose;
__PACKAGE__->meta->make_immutable;

