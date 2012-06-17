package Lacuna::Verify;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Regexp::Common;
use Email::Valid;

has content => (
    is          => 'ro',
    required    => 1,
);

has throws => (
    is          => 'ro',
    required    => 1,
    writer      => '_throws',
);

sub ok {
    my ($self, $test) = @_;
    unless ($test) {
        confess $self->throws;
    }
    return $self;
}

sub not_ok {
    my ($self, $test) = @_;
    return $self->ok(!$test);
}

sub eq {
    my ($self, $val) = @_;
    return $self->ok(${$self->content} eq $val);
}

sub ne {
    my ($self, $val) = @_;
    return $self->ok(${$self->content} ne $val);
}

sub empty {
    my $self = shift;
    return $self->ok(${$self->content} eq '');
}

sub not_empty {
    my $self = shift;
    return $self->ok(${$self->content} ne '' && ${$self->content} =~ m/\S+/xms);
}

sub no_profanity {
    my $self = shift;
    my @bad_words = lc(${$self->content}) =~ /$RE{profanity}{-keep}/g;
    if (@bad_words)
    {
        my %word_count;
        $word_count{$_}++ for @bad_words;
        my $throws = $self->throws;
        my $msg    = $throws->[1] . ' (';
        $msg      .= join ', ', map {
            my $s = $_;
            $s   .= " (x$word_count{$_})" if $word_count{$_} != 1;
            $s;
        } sort keys %word_count;
        $msg      .= ')';
        $throws->[1] = $msg
    }
    return $self->ok(@bad_words == 0);
}

sub no_restricted_chars {
    my $self = shift;
    return $self->ok(${$self->content} !~ m/[@&<>;\{\}\(\)]/);
}

sub no_match {
    my $self = shift;
    my $re   = shift;
    return $self->ok(${$self->content} !~ $re);
}

sub only_ascii {
    my $self = shift;
    my %good  = map {$_ => 1} (32..126);
    my $filtered = ${$self->content};
    $filtered =~ s/(.)/$good{ord($1)} ? $1 : ''/eg;
    return $self->ok($filtered eq ${$self->content});
}

sub no_padding {
    my $self = shift;
    return $self->ok(${$self->content} !~ m/^\s/ && ${$self->content} !~ m/\s\s/ && ${$self->content} !~ m/\s$/);
}

sub no_tags {
    my $self = shift;
    return $self->ok(${$self->content} !~ m/[<>]/);
}

sub length_gt {
    my ($self, $length) = @_;
    return $self->ok(length(${$self->content}) > $length);
}

sub length_lt {
    my ($self, $length) = @_;
    return $self->ok(length(${$self->content}) < $length);
}

sub is_email {
    my ($self) = @_;
    return $self->ok(Email::Valid->address(${$self->content}));
}


no Moose;
__PACKAGE__->meta->make_immutable;
