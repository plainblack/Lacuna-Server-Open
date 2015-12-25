package Lacuna::DB::Result::Promotion::ECode50;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Promotion::EssentiaCode';

use constant title => '50% Essentia Code Bonus';
use constant bonus_percent => 50;

sub description {
    my ($self) = @_;

    sprintf "receive an essentia code worth %d%% of your purchase that you can give to whomever you like!", $self->bonus_percent;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
