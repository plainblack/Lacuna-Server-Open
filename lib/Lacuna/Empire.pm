package Lacuna::Empire;

use Moose;
extends 'JSON::RPC::Dispatcher::App';

has simpledb => (
    is      => 'ro',
    required=> 1,
);

sub is_name_available {
    my ($self, $name) = @_;
    if ( $name eq '' ) {
        return 0;
    }
    else {
        my $count = $self->simpledb->domain('empire')->count({name=>$name});
        return !$count;
    }
}

sub login {
    my ($self, $name, $password) = @_;
    my $empire = $self->simpledb->domain('empire')->search({name=>$name})->next;
    if (defined $empire) {
        if ($empire->authenticate_password($password)) {
            return $empire->start_session->id;
        }
        else {
            die [1004, 'Password incorrect.', $password];
        }
    }
    else {
        die [1005, 'Empire does not exist.', $name];
    }
}

sub create_empire {
    my ($self, %account) = @_;
    if ( $account{name} eq '' || !$self->is_name_available($account{name})) {
        die [1000,'Empire name not available.', $account{name}];
    }
    elsif ($account{password} eq '' || length($account{password}) < 6 || $account{password} ne $account{password1})  {
        die [1001,'Invalid password.', $account{password}];
    }
    elsif ($account{species_id} eq '' || !$self->simpledb->domain('species')->find($account{species_id}))  {
        die [1002, 'Invalid species.', $account{species_id}];
    }
    else {
        my $empire = $self->simpledb->domain('empire')->insert({
            name            => $account{name},
            date_created    => DateTime->now,
            password        => $account{password},
            species_id      => $account{species_id},
        });
        return { empire_id => $empire->id, session => $empire->start_session->id };
    }
}

__PACKAGE__->register_rpc_method_names(qw(is_name_available create_empire login));


no Moose;
__PACKAGE__->meta->make_immutable;

