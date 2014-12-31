package Lacuna::Verify;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Regexp::Common qw(RE_profanity);
use Email::Valid;

has content => (
    is          => 'ro',
    required    => 1,
);

has throws => (
    is          => 'ro',
    required    => 1,
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
    return $self->ok(lc(${$self->content}) !~ RE_profanity());
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
