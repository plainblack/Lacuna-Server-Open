package Lacuna::RPC::EssentiaCode;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use DateTime;
use UUID::Tiny ':std';

sub verify_key {
    my ($self, $key) = @_;
    return $key ~~ Lacuna->config->get('server_keys') ? 1 : 0;
}

sub spend {
    my ($self, $key, $code_string) = @_;
    confess [401, 'Invalid key.'] unless $self->verify_key($key);
    my $code = Lacuna->db->resultset('Lacuna::DB::Result::EssentiaCode')->search({code => $code_string})->first;
    confess [1002, 'The essentia code you specified is invalid.'] unless (defined $code);
    confess [1010, 'The essentia code you specified has already been redeemed.'] if ($code->used);
    $code->used(1);
    $code->update;
    return $code->amount;
}

sub add {
    my ($self, $key, $amount, $description) = @_;
    confess [401, 'Invalid key.'] unless $self->verify_key($key);
    confess [1009, 'Amount must be 0 or higher.'] unless $amount >= 0;
    confess [1009, 'You must supply a description'] unless length($description);
    my $code_string = create_uuid_as_string(UUID_V4);
    my $code = Lacuna->db->resultset('Lacuna::DB::Result::EssentiaCode')->new({
        code            => $code_string,
        date_created    => DateTime->now,
        description     => $description,
        amount          => $amount,
    })->insert;
    return $code_string;
}

__PACKAGE__->register_rpc_method_names(
    qw(add spend),
);


no Moose;
__PACKAGE__->meta->make_immutable;

