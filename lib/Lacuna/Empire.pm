package Lacuna::Empire;

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Util qw(cname);
use Digest::SHA;

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
        my $count = $self->simpledb->domain('empire')->count({cname=>cname($name)});
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
    my $empire = $self->simpledb->domain('empire')->search({cname=>cname($name)})->next;
    if (defined $empire) {
        if ($empire->password eq $self->encrypt_password($password)) {
            return $empire->start_session->id;
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
    $account{species_id} ||= 'human_species';
    if ( $account{name} eq '' || length($account{name}) > 30 || $account{name} =~ m/[@&<>;]/ || !$self->is_name_available($account{name})) {
        confess [1000,'Empire name not available.', $account{name}];
    }
    elsif (length($account{password}) < 6 || $account{password} ne $account{password1})  {
        confess [1001,'Invalid password.', $account{password}];
    }
    elsif ($account{species_id} eq '' || !$self->simpledb->domain('species')->find($account{species_id}))  {
        confess [1002, 'Invalid species.', $account{species_id}];
    }
    else {
        my $empire = $self->simpledb->domain('empire')->insert({
            name            => $account{name},
            date_created    => DateTime->now,
            password        => $self->encrypt_password($account{password}),
            species_id      => $account{species_id},
        });
        return { empire_id => $empire->id, session_id => $empire->start_session->id };
    }
}

sub encrypt_password {
    my ($self, $password) = @_;
    return Digest::SHA::sha256_base64($password);
}


__PACKAGE__->register_rpc_method_names(qw(is_name_available create login logout));


no Moose;
__PACKAGE__->meta->make_immutable;

