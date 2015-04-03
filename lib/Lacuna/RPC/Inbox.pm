package Lacuna::RPC::Inbox;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use DateTime;
use Lacuna::Verify;
use Lacuna::Util qw(format_date);
use List::Util qw(none);


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
        message => {
            id          => $message->id,
            from        => $message->from_name,
            from_id     => $message->from_id,
            to          => $message->to_name,
            to_id       => $message->to_id,
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
        status  => $self->format_status($empire),
    };
}

sub archive_messages {
    my ($self, $session_id, $message_ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $messages = Lacuna->db->resultset('Lacuna::DB::Result::Message')
        ->search(
                 {
                     id => [ 'in', $message_ids ],
                     to_id => $empire->id,
                     has_archived => 0,
                 });

    my @updating = map { $_->id } $messages->search(undef, { columns => [ 'id' ]})->all;
    if (@updating)
    {
        $messages->update(
                          {
                              has_read => 1,
                              has_archived => 1,
                              has_trashed => 0
                          });
        $empire->recalc_messages;
    }

    return { success=>\@updating, status=>$self->format_status($empire) };
}

sub trash_messages {
    my ($self, $session_id, $message_ids) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $messages = Lacuna->db->resultset('Lacuna::DB::Result::Message')
        ->search(
                 {
                     id => [ 'in', $message_ids ],
                     to_id => $empire->id,
                     has_trashed => 0,
                 });

    my @updating = map { $_->id } $messages->search(undef, { columns => [ 'id' ]})->all;
    if (@updating)
    {
        $messages->update(
                          {
                              has_read => 1,
                              has_archived => 0,
                              has_trashed => 1,
                          });
        $empire->recalc_messages;
    }

    return { success=>\@updating, status=>$self->format_status($empire) };
}

sub trash_messages_where {
    my ($self, $session_id, $opts) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if (!$opts->{spec})
    {
        $opts = { spec => [ @_[2..$#_] ] };
    }

    # initialise deleted_count to ensure it gets set on return
    my %return = (deleted_count => 0);

    # if we're saving returns, same thing, ensure there's an empty
    # list even if nothing is deleted.
    $return{deleted} = [] if $opts->{save_ids};

    my $count = -1;

    for my $spec (@{$opts->{spec}})
    {
        ++$count;
        my %where;
        $where{tag}       = $spec->{tags}     if $spec->{tags} &&  ref $spec->{tags} eq 'ARRAY';
        $where{tag}     ||= $spec->{tag}      if $spec->{tag}  && !ref $spec->{tag};
        $where{from_name} = [ $spec->{from} ] if $spec->{from} && !ref $spec->{from};

        if ($spec->{subject})
        {
            # some variation allowed, but need to ensure sanity.

            # only allow lists of subjects as explicit items, and each one
            # must be a string only - no nested objects, because DBIx::Class
            # will do more stuff down lower, and we really don't want to ensure
            # its security.
            if (ref $spec->{subject} &&
                ref $spec->{subject} eq 'ARRAY' &&
                none { ref $_ } @{$spec->{subject}})
            {
                $where{subject} = $spec->{subject};
            }
            # single string, with % or _, use like
            elsif ($spec->{subject} =~ /[%_]/)
            {
                $where{subject} = { like => $spec->{subject} };
            }
            # otherwise, just match directly.
            elsif (not ref $spec->{subject})
            {
                $where{subject} = $spec->{subject};
            }
            # if we got some other sort of ref, craok instead of trying
            # to ensure security.
            else
            {
                confess [ 1009, 'Invalid subject specified for mass delete' ];
            }
        }

        confess [ 1009, 'No options specified for mass delete spec #' . $count ]
            unless keys %where;

        # the parts the caller can't override:
        $where{has_archived} = 0;
        $where{to_id}        = $empire->id;
        $where{has_trashed}  = 0; # only look at ones not already trashed

        my $messages = Lacuna->db->resultset('Lacuna::DB::Result::Message')->search(\%where);

        # check if we have anything to delete
        my $count;
        if ($opts->{save_ids})
        {
            my @deleting = map { $_->id } $messages->search(undef, { columns => [ 'id' ] })->all;
            if (@deleting)
            {
                $count = @deleting;
                push @{$return{deleted}}, @deleting;
            }
        }
        else
        {
            $count = $messages->count;
        }

        # delete it
        if ($count)
        {
            $return{deleted_count} += $count;
            $messages->update(
                              {
                                  has_read => 1,
                                  has_trashed => 1,
                              });
        }
    }

    $empire->recalc_messages if $return{deleted_count};

    $return{status} = $self->format_status($empire);
    return \%return;
}

sub send_message {
    my ($self, $session_id, $recipients, $subject, $body, $options) = @_;
    Lacuna::Verify->new(content=>\$subject, throws=>[1005,'Message subject cannot be empty.',$subject])->not_empty;
    Lacuna::Verify->new(content=>\$subject, throws=>[1005,'Message subject cannot contain any of these characters: (){}<>&;@',$subject])->no_restricted_chars;
    Lacuna::Verify->new(content=>\$subject, throws=>[1005,'Message subject must be less than 100 characters.',$subject])->length_lt(100);
    Lacuna::Verify->new(content=>\$body, throws=>[1005,'Message body cannot be empty.',$body])->not_empty;
    Lacuna::Verify->new(content=>\$body, throws=>[1005,'Message body cannot contain HTML tags or entities.',$body])->no_tags;
    my $empire = $self->get_empire_by_session($session_id);
    if ($options->{in_reply_to}) {
        my $reply_to = Lacuna->db->resultset('Lacuna::DB::Result::Message')->find($options->{in_reply_to});
        unless ($empire->id ~~ [$reply_to->to_id, $reply_to->from_id]) {
            confess [1010, 'You cannot reply to a message id that you cannot read.'];
        }
    }
    my $attachments = {};
    if ($options->{forward}) {
        my $forward = Lacuna->db->resultset('Lacuna::DB::Result::Message')->find($options->{forward});
        unless ($empire->id ~~ [$forward->to_id, $forward->from_id]) {
            confess [1010, 'You cannot forward a message id that you cannot read.'];
        }
        $attachments = $forward->attachments;
    }
    my @sent;
    my @unknown;
    my @to;
    my $cache = Lacuna->cache;
    my $cache_key = 'mail_send_count_'.format_date(undef,'%d');
    my $send_count = $cache->get($cache_key,$empire->id);
    foreach my $name (split /\s*,\s*/, $recipients) {
        next if $name eq '';
        if ($name eq '@ally') {
            if ($empire->alliance_id) {
                my $allies = $empire->alliance->members;
                while (my $ally = $allies->next) {
                    push @sent, $ally->name;
                    push @to, $ally;
                    $send_count++;
                }
            }
            else {
                push @unknown, '@ally';
            }
        }
        else {
            my $user = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name => $name})->first;
            if (defined $user) {
                push @sent, $user->name;
                push @to, $user;
                $send_count++;
            }
            else {
                push @unknown, $name;
            }
        }
    }
    my $max_messages = 100 + int((time - $empire->date_created->epoch)/3600) + ( $empire->alliance_id ? 50 : 0 );
    if ($send_count > $max_messages) {
        confess [1010, "You have already sent the maximum number (".$max_messages.") of messages you can send for one day."];
    }
    foreach my $to (@to) {
        if ($to->id == 1) {
            Lacuna::Tutorial->new(empire=>$empire)->finish(1);
        }
        else {
            $to->send_message(
                from        => $empire,
                subject     => $subject,
                body        => $body,
                in_reply_to => $options->{in_reply_to},
                recipients  => \@sent,
                tag         => 'Correspondence',
                attachments => $attachments,
            );
        }
    }
    $cache->set($cache_key, $empire->id, $send_count, 60 * 60 * 24);
    return {
        message => {
            sent    => \@sent,
            unknown => \@unknown,
        },
        status  => $self->format_status($empire),
    };
}

sub view_inbox {
    my $self = shift;
    my $session_id = shift;
    my $empire = $self->get_empire_by_session($session_id);
    my $where = {
        has_archived    => 0,
        has_trashed     => 0,
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
        has_trashed     => 0,
        to_id           => $empire->id,
    };
    return $self->view_messages($where, $empire, @_);
}

sub view_trashed {
    my $self = shift;
    my $session_id = shift;
    my $empire = $self->get_empire_by_session($session_id);
    my $where = {
        has_archived    => 0,
        has_trashed     => 1,
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

sub view_unread {
    my $self = shift;
    my $session_id = shift;
    my $empire = $self->get_empire_by_session($session_id);
    my $where = {
        has_archived    => 0,
        has_read        => 0,
        to_id           => $empire->id,
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
            from_id         => $message->from_id,
            to              => $message->to_name,
            to_id           => $message->to_id,
            has_read        => $message->has_read,
            has_replied     => $message->has_replied,
            body_preview    => substr($message->body,0,30),
            tags            => [$message->tag],
        };
    }
    return {
        messages        => \@box,
        message_count   => $messages->pager->total_entries,
        status          => $self->format_status($empire),
    };
}

__PACKAGE__->register_rpc_method_names(qw(view_inbox view_archived view_trashed view_sent view_unread send_message read_message archive_messages trash_messages trash_messages_where));


no Moose;
__PACKAGE__->meta->make_immutable;

