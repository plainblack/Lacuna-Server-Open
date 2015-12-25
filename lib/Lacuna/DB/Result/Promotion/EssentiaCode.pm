package Lacuna::DB::Result::Promotion::EssentiaCode;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Promotion';
use UUID::Tiny ':std';

use constant category => 'essentia_purchase';
sub title {
    my ($self) = @_;
    sprintf '%d%% Essentia Code Bonus', $self->bonus_percent;
}

sub essentia_purchased
{
    my ($self, $opts) = @_;

    my $bonus = int( $opts->{amount} * $self->bonus_percent() / 10 + 0.5 ) / 10;
    my $empire = $opts->{empire};

    my $code = Lacuna->db->resultset('EssentiaCode')->new({
        date_created    => DateTime->now,
        amount          => $bonus,
        description     => sprintf("Bonus Ecode for %s",$empire->name),
        code            => create_uuid_as_string(UUID_V4),
    })->insert;

    $empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'promo/essentia_code.txt',
        params      => [$self->bonus_percent(), $bonus, $code->code],
    );

}

sub description {
    my ($self) = @_;

    sprintf "receive an essentia code worth %d%% of your purchase!", $self->bonus_percent;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
