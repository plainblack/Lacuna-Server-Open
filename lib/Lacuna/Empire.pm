package Lacuna::Empire;

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Util qw(cname);
use Lacuna::Map;
use Lacuna::Verify;
use Lacuna::DB::Empire;

has simpledb => (
    is      => 'ro',
    required=> 1,
);

with 'Lacuna::Role::Sessionable';

sub is_name_available {
    my ($self, $name) = @_;
    if ( $name eq '' ) {
        return 0;
    }
    else {
        my $count = $self->simpledb->domain('empire')->count(where=>{name_cname=>cname($name)}, consistent=>1);
        return ($count) ? 0 : 1;
    }
}

sub logout {
    my ($self, $session_id) = @_;
    $self->get_session($session_id)->delete;
    return 1;
}

sub login {
    my ($self, $name, $password) = @_;
    my $empire = $self->simpledb->domain('empire')->search(where=>{name_cname=>cname($name)})->next;
    if (defined $empire) {
        if ($empire->is_password_valid($password)) {
            return { session_id => $empire->start_session->id, status => $empire->get_full_status };
        }
        else {
            confess [1004, 'Password incorrect.', $password];
        }
    }
    else {
         confess [1002, 'Empire does not exist.', $name];
    }
}

sub create {
    my ($self, %account) = @_;
    Lacuna::Verify->new(content=>\$account{password}, throws=>[1001,'Invalid password.', $account{password}])
        ->length_gt(5)
        ->eq($account{password1});

    Lacuna::Verify->new(content=>\$account{name}, throws=>[1000,'Empire name not available.', $account{name}])
        ->length_lt(31)
        ->length_gt(2)
        ->no_restricted_chars
        ->no_profanity
        ->ok($self->is_name_available($account{name}));

    my $empire = Lacuna::DB::Empire->create($self->simpledb, \%account);
    return $empire->id;
}


sub found {
    my ($self, $empire_id) = @_;
    my $empire = $self->simpledb->domain('empire')->find($empire_id);
    unless (defined $empire) {
        confess [1002, "Invalid empire."];
    }
    $empire->found;

    return { session_id => $empire->start_session->id, status => $empire->get_full_status };
}


sub get_status {
    my ($self, $session_id) = @_;
    return $self->get_empire_by_session($session_id)->get_status;
}

sub get_full_status {
    my ($self, $session_id) = @_;
    return $self->get_empire_by_session($session_id)->get_full_status;
}


__PACKAGE__->register_rpc_method_names(qw(is_name_available create found login logout get_full_status get_status));


no Moose;
__PACKAGE__->meta->make_immutable;

