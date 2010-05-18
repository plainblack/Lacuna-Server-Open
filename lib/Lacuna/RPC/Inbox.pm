package Lacuna::RPC::Inbox;

use Moose;
extends 'Lacuna::RPC';
use DateTime;
use Lacuna::Verify;



sub read_message {
    my ($self, $session_id, $message_id) = @_;
    my $message = Lacuna->db->resultset('Lacuna::DB::Result::Message')->find($message_id);
    unless (defined $message) {
        confess [1002, 'Message does not exist.', $message_id];
    }
    my $empire = $self->get_empire_by_session($session_id);
    unless ($empire->id ~~ [$message->from_id, $message->to_id]) {
        confess [1010, "You can't read a message that isn't yours.", $message_id];
    }
    if ($empire->id eq $message->to_id && !$message->has_read) {
        $message->has_read(1);
        $message->update;
    }
    return {
        status  => $self->format_status,
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
            tags        => [$message->tag],
            attachments => $message->attachments,
        },
    };
}

sub archive_messages {
    my ($self, $session_id, $message_ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $messages = Lacuna->db->resultset('Lacuna::DB::Result::Message');
    my @failure;
    my @success;
    foreach my $id (@{$message_ids}) {
        my $message = $messages->find($id);
        if (defined $message && $empire->id eq $message->to_id && !$message->has_archived) {
            $message->has_archived(1);
            $message->update;
            push @success, $id;
        }
        else {
            push @failure, $id;
        }
    }
    return { success=>\@success, failure=>\@failure, status=>$self->format_status };
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
        ->no_tags
        ->no_profanity;
    my $empire = $self->get_empire_by_session($session_id);
    my @sent;
    my @unknown;
    my @to;
    foreach my $name (split /\s*,\s*/, $recipients) {
        next if $name eq '';
        my $user = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name => $name})->next;
        if (defined $user) {
            push @sent, $user->name;
            push @to, $user;
        }
        else {
            push @unknown, $name;
        }
    }
    foreach my $to (@to) {
        if ($to->id eq 'lacuna_expanse_corp') {
            Lacuna::Tutorial->new(empire=>$empire)->finish;
        }
        else {
            $to->send_message(
                from        => $empire,
                subject     => $subject,
                body        => $body,
                in_reply_to => $options->{in_reply_to},
                recipients  => \@sent,
                tag         => 'Correspondence',
            );
        }
    }
    return {
        message => {
            sent    => \@sent,
            unknown => \@unknown,
        },
        status  =>$self->format_status,
    };
}

sub view_inbox {
    my $self = shift;
    my $session_id = shift;
    my $empire = $self->get_empire_by_session($session_id);
    my $where = {
        has_archived    => {'!=' => 1},
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
        from_id         => $empire->id,
        to_id           => {'!=' => $empire->id},
    };
    return $self->view_messages($where, $empire, @_);
}

sub view_messages {
    my ($self, $where, $empire, $options) = @_;
    $options->{page_number} ||= 1;
    if ($options->{tags}) {
        $where->{tag} = ['in',$options->{tags}];
    }
    my $messages = Lacuna->db->resultset('Lacuna::DB::Result::Message')->search(
        $where,
        {
            order_by    => { -desc => 'date_sent' },
            rows        => 25,
            page        => $options->{page_number},
        }
    );
    my @box;
    while (my $message = $messages->next) {
        push @box, {
            id              => $message->id,
            subject         => $message->subject,
            date            => $message->date_sent_formatted,
            from            => $message->from_name,
            to              => $message->to_name,
            has_read        => $message->has_read,
            has_replied     => $message->has_replied,
            body_preview    => substr($message->body,0,30),
            tags            => [$message->tag],
        };
    }
    return {
        messages        => \@box,
        message_count   => $messages->pager->total_entries,
        status          => $self->format_status,
    };
}

__PACKAGE__->register_rpc_method_names(qw(view_inbox view_archived view_sent send_message read_message archive_messages));


no Moose;
__PACKAGE__->meta->make_immutable;

