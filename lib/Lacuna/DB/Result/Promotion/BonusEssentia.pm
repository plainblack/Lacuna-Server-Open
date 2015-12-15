package Lacuna::DB::Result::Promotion::BonusEssentia;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Promotion';

use constant category => 'essentia_purchase';

sub essentia_purchased
{
    my ($self, $opts) = @_;

    my $bonus = int( $opts->{amount} * $self->bonus_percent() / 10 + 0.5 ) / 10;
    my $empire = $opts->{empire};

    $empire->add_essentia({
        amount          => $bonus,
        reason          => sprintf('Bonus %d%%', $self->bonus_percent()),
        type            => 'paid',
        transaction_id  => $opts->{transaction_id},
    });
    $empire->update;
    $empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'promo/bonus_essentia.txt',
        params      => [$self->bonus_percent(), $bonus, $opts->{transaction_id}],
    );
    
}

sub description {
    my ($self) = @_;

    sprintf "receive a %d%% bonus!", $self->bonus_percent;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
